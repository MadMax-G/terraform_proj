# Your First Terraform Project

This repository contains a simple but powerful Terraform project. You are welcome to use this code as a jumping-off point for your infrastructure as code journey!

## Setup

For this project to run, you must first initiate a `secrets.tfvars` file. This file will secure your "admin_username" and "admin_password". It should be structured as shown below:

```
admin_username = "<your_username>"
admin_password = "<your_password>"
```
Replace "<your_username>" and "<your_password>" accordingly.

## Running the project

With the `secrets.tfvars` file in place, you can run the following command:

```
terraform apply -var-file="secrets.tfvars"
```
By doing so, the Terraform project will execute. It will reference the `secrets.tfvars` file to securely access the required admin username and password. This ensures your sensitive data does not get exposed in your code base.

## Learn and Contribute

Feel free to use my code as a reference to learn Terraform and Infra-as-code concepts. If you have improvements or suggestions, don't hesitate to contribute or give feedback.

Happy Coding!
