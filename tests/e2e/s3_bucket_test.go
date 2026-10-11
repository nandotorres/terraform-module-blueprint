package test

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"io"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/gruntwork-io/terratest/modules/terraform/v2"
	"github.com/stretchr/testify/require"
)

const (
	region             = "us-east-1"
	localstackEndpoint = "http://localhost:4566"
	objectKey          = "hello.txt"
	objectBody         = "hello"
)

func TestS3BucketOnLocalStack(t *testing.T) {
	ctx := context.Background()
	bucketName := "example-" + uniqueSuffix(t)

	env := map[string]string{
		"AWS_ACCESS_KEY_ID":         "test",
		"AWS_SECRET_ACCESS_KEY":     "test",
		"AWS_DEFAULT_REGION":        region,
		"AWS_EC2_METADATA_DISABLED": "true",
		"AWS_ENDPOINT_URL":          localstackEndpoint,
		// SDK v2 checksum defaults are rejected by LocalStack 4.14.
		"AWS_REQUEST_CHECKSUM_CALCULATION": "when_required",
		"AWS_RESPONSE_CHECKSUM_VALIDATION": "when_required",
	}
	for key, value := range env {
		t.Setenv(key, value)
	}

	options := &terraform.Options{
		TerraformDir: "../../examples/complete",
		NoColor:      true,
		Vars: map[string]interface{}{
			"bucket_name":         bucketName,
			"force_destroy":       true,
			"expiration_days":     7,
			"localstack_endpoint": localstackEndpoint,
			"tags": map[string]string{
				"Environment": "test",
				"Owner":       "platform",
			},
		},
		EnvVars: env,
	}

	defer terraform.DestroyContext(t, ctx, options)
	terraform.InitAndApplyContext(t, ctx, options)

	require.Equal(t, bucketName, terraform.OutputContext(t, ctx, options, "bucket_id"))
	require.Contains(t, terraform.OutputContext(t, ctx, options, "bucket_arn"), bucketName)

	client := newS3Client(t, ctx)
	assertPublicAccessBlocked(t, ctx, client, bucketName)
	assertVersioningEnabled(t, ctx, client, bucketName)
	assertEncrypted(t, ctx, client, bucketName)
	assertOwnership(t, ctx, client, bucketName)
	assertTags(t, ctx, client, bucketName)
	assertLifecycle(t, ctx, client, bucketName)
	assertRoundTrip(t, ctx, client, bucketName)
}

func newS3Client(t *testing.T, ctx context.Context) *s3.Client {
	t.Helper()

	cfg, err := config.LoadDefaultConfig(ctx,
		config.WithRegion(region),
		config.WithCredentialsProvider(credentials.NewStaticCredentialsProvider("test", "test", "")),
	)
	require.NoError(t, err)

	return s3.NewFromConfig(cfg, func(options *s3.Options) {
		options.BaseEndpoint = aws.String(localstackEndpoint)
		options.UsePathStyle = true // localhost has no virtual-hosted bucket DNS
	})
}

func assertPublicAccessBlocked(t *testing.T, ctx context.Context, client *s3.Client, bucket string) {
	t.Helper()

	out, err := client.GetPublicAccessBlock(ctx, &s3.GetPublicAccessBlockInput{Bucket: aws.String(bucket)})
	require.NoError(t, err)
	require.NotNil(t, out.PublicAccessBlockConfiguration)
	cfg := out.PublicAccessBlockConfiguration
	require.True(t, aws.ToBool(cfg.BlockPublicAcls))
	require.True(t, aws.ToBool(cfg.BlockPublicPolicy))
	require.True(t, aws.ToBool(cfg.IgnorePublicAcls))
	require.True(t, aws.ToBool(cfg.RestrictPublicBuckets))
}

func assertVersioningEnabled(t *testing.T, ctx context.Context, client *s3.Client, bucket string) {
	t.Helper()

	out, err := client.GetBucketVersioning(ctx, &s3.GetBucketVersioningInput{Bucket: aws.String(bucket)})
	require.NoError(t, err)
	require.Equal(t, types.BucketVersioningStatusEnabled, out.Status)
}

func assertEncrypted(t *testing.T, ctx context.Context, client *s3.Client, bucket string) {
	t.Helper()

	out, err := client.GetBucketEncryption(ctx, &s3.GetBucketEncryptionInput{Bucket: aws.String(bucket)})
	require.NoError(t, err)
	require.NotEmpty(t, out.ServerSideEncryptionConfiguration.Rules)
	rule := out.ServerSideEncryptionConfiguration.Rules[0].ApplyServerSideEncryptionByDefault
	require.NotNil(t, rule)
	require.Equal(t, types.ServerSideEncryptionAes256, rule.SSEAlgorithm)
}

func assertOwnership(t *testing.T, ctx context.Context, client *s3.Client, bucket string) {
	t.Helper()

	out, err := client.GetBucketOwnershipControls(ctx, &s3.GetBucketOwnershipControlsInput{Bucket: aws.String(bucket)})
	require.NoError(t, err)
	require.NotEmpty(t, out.OwnershipControls.Rules)
	require.Equal(t, types.ObjectOwnershipBucketOwnerEnforced, out.OwnershipControls.Rules[0].ObjectOwnership)
}

func assertTags(t *testing.T, ctx context.Context, client *s3.Client, bucket string) {
	t.Helper()

	out, err := client.GetBucketTagging(ctx, &s3.GetBucketTaggingInput{Bucket: aws.String(bucket)})
	require.NoError(t, err)

	tags := map[string]string{}
	for _, tag := range out.TagSet {
		tags[aws.ToString(tag.Key)] = aws.ToString(tag.Value)
	}
	require.Equal(t, "test", tags["Environment"])
	require.Equal(t, "platform", tags["Owner"])
	require.Equal(t, "terraform", tags["ManagedBy"])
	require.Equal(t, "s3_bucket", tags["Module"])
}

func assertLifecycle(t *testing.T, ctx context.Context, client *s3.Client, bucket string) {
	t.Helper()

	out, err := client.GetBucketLifecycleConfiguration(ctx, &s3.GetBucketLifecycleConfigurationInput{Bucket: aws.String(bucket)})
	require.NoError(t, err)
	require.NotEmpty(t, out.Rules)
	require.NotNil(t, out.Rules[0].Expiration)
	require.NotNil(t, out.Rules[0].Expiration.Days)
	require.Equal(t, int32(7), *out.Rules[0].Expiration.Days)
}

func assertRoundTrip(t *testing.T, ctx context.Context, client *s3.Client, bucket string) {
	t.Helper()

	_, err := client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(objectKey),
		Body:   strings.NewReader(objectBody),
	})
	require.NoError(t, err)

	out, err := client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(bucket),
		Key:    aws.String(objectKey),
	})
	require.NoError(t, err)
	defer out.Body.Close()

	body, err := io.ReadAll(out.Body)
	require.NoError(t, err)
	require.Equal(t, objectBody, string(body))
	require.NotEmpty(t, aws.ToString(out.VersionId))
}

func uniqueSuffix(t *testing.T) string {
	t.Helper()

	buf := make([]byte, 4)
	_, err := rand.Read(buf)
	require.NoError(t, err)
	return hex.EncodeToString(buf)
}
