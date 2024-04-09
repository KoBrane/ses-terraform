# Use the official Alpine Linux image as the base
FROM alpine:3.17

# Install required packages
RUN apk --no-cache add curl bash git

# Install Terraform
ENV TERRAFORM_VERSION=1.4.6
RUN curl -sL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip" -o terraform.zip && \
    unzip terraform.zip && \
    mv terraform /usr/local/bin/ && \
    rm terraform.zip

# Install tflint
RUN curl -sL "https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh" | bash

# Install tfsec
RUN curl -sL "https://raw.githubusercontent.com/aquasecurity/tfsec/master/install.sh" | bash

# Set the working directory
WORKDIR /workspace

# Copy the entire repository into the container
COPY . .