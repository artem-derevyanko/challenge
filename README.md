# Challenge

This is a dockerized application.

## Local Development

### System requirements

For local application starting (for development) make sure that you have locally installed next applications:
- `docker >= 19`
	([installing manual](https://docs.docker.com/engine/install/ubuntu/))
- `docker-compose >= 1.24` ([installing manual](https://docs.docker.com/compose/install/)
- `make >= 4.2.1` _(install: `apt-get install make`)_

### Development

1. Clone this repository on your machine
2. `cd challenge`
3. Rename `www/.env.example` to `www/.env.local` (`cp www/.env.example www/.env.local`) and fill in values if it's need
4. Rename `.env.example` to `.env.local` (`cp .env.example .env.local`) and fill in values if it's need
5. `make up`
6. `make start-dev`
7.  Open [app](http://localhost:3000/) in your browser

**[NOTE]** To change data source you need to set `JSON_SOURCE_PATH` environment variable. You can specify any HTTP
url or path to file in your file system. By default, it's `data/data.json`.

## Used services

This application uses next services:

- Next.js 12.0.4
- PostgreSQL 13.1
- Hasura 2.0.10

Declaration of all services can be found into `./docker-compose.*.yaml` files.

## Working with application

Most used commands declared in `./Makefile` file:

| Command signature        | Description                                                                               |
| ------------------------ | ----------------------------------------------------------------------------------------- |
| `make help`              | Get this help                                                                             |
| `make up`                | Set up application (start all containers in background and migrate db)                    |
| `make down`              | Stop application                                                                          |
| `make start-dev`         | Start application for local development                                                   |  |
| `make shell`             | Shell node container                                                                      |  |
| `make sync-db`           | Sync all db changes (you can specify argument `MODE` to `production`/`local` (by default) |
| `make init-release`      | Initialize first release on AWS                                                           |
| `make release`           | Start release on AWS (Deploy infrastructure on AWS)                                       |
| `make destroy-release`   | Destroy all resources for created release on AWS                                          |
| `make deploy`            | Deploy app changes to AWS                                                                 |
| `docker-compose down -v` | Stop all application containers and **remove all application data** (database, etc)       |

After application starting you can open [http://localhost:3000](http://localhost:3000) in your browser.

# Deploy application

## Example app

Go to [example](http://app-lb-1413657223.us-west-2.elb.amazonaws.com)

## Prerequirements:

**[NOTE]** Yeap, in future all this applications and steps will be cool to move to CI/CD.

For deploying your application make sure that you have locally installed next applications:
- `docker >= 19`
	([installing manual](https://docs.docker.com/engine/install/ubuntu/))
- `docker-compose >= 1.24` ([installing manual](https://docs.docker.com/compose/install/))
- `make >= 4.2.1` _(install: `apt-get install make`)_
- `terraform >= 1.0.11` ([installing manual](https://www.terraform.io/downloads.html))
- `aws-cli` ([installing manual](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)) or any another way to work with your AWS resources.

1. Create an IAM account in your AWS (you'll get `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`)
2. Run `aws configure` and enter `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` or you can use any another way to auth yourself into AWS account.

## First deployment:

1. Move to project root
2. `make init-release`
3. Rename `example.tfvars` to `production.tfvars` (`cp infrastracture/terraform/example.tfvars infrastracture/terraform/production.tfvars`) and fill in all values.
4. `make release`
5. Rename `www/.env.example.production` to `www/.env.production` (`cp www/.env.example.production www/.env.production`)
5. Rename `.env.example.production` to `.env.production` (`cp .env.example.production .env.production`)
6. You'll get Terraform output from previous command, so use it and fill in `.env.production` and `www/.env.production` variables.
7. `make deploy` (*)
8. `make sync-db mode=production`

[NOTE] (*) In order to push docker image to AWS ECR you need to log in into ECR (`aws ecr get-login` or any other appropriate way [How to log in into AWS ECR](https://serverfault.com/questions/1004915/what-is-the-proper-way-to-log-in-to-ecr) or [Auth into AWS ECR](https://docs.aws.amazon.com/AmazonECR/latest/userguide/getting-started-cli.html#cli-authenticate-registry))

## Following deploys:

1. Make changes in your code
2. Commit it (optional)
3. `make deploy`
4. `make sync-db mode=production` (only if you have any changes in your Hasura)
