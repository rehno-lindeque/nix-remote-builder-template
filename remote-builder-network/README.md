# Nix remote builder

## Preparing an environment with secrets

### AWS access key

You may use your default aws credentials as per usual with nixops. Otherwise you can explicitly specify them:

1. Create a file `./secret/.my-envrc` with your AWS credentials.

```
export EC2_ACCESS_KEY="XXXXXXXXXXXXXXXXXXXX"
export EC2_SECRET_KEY="XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
```

(You can generate a new credentials under your [AWS IAM account settings](https://console.aws.amazon.com/iam/home?#/security_credentials))

2. Run `direnv allow` in the root directory


## Prepare to deploy the network for the first time

```
builder-ops create flake.nix
```

Before deploying, carefully inspect all the files in this template in order to make sure you understand what it will do.

