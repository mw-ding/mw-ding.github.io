---
title: "Build A Personal Site on AWS Like This One in 15 Minutes"
tags: ["aws", "s3", "blogging", "git", "markdown"]
date: 2017-11-05T23:07:17-08:00
draft: true
---

I was looking for a simple solution recently to host a lightweight personal
site with the following features:

1. Write in Markdown
2. Manage with Git
3. Auto deployment after push

You might suggest [GitHub Pages + Jekyll](https://help.github.com/articles/using-jekyll-as-a-static-site-generator-with-github-pages/).
But I am not quite fond of hosting it on Github (for no reason) and would
prefer AWS since I am experienced with AWS environment due to my daily
engineering work.

I did some quick search and successfully assembled a pipeline to achieve this.
So I just wrapped up this post a summarization. Hopefully, this is helpful for 
you as well.

The following tools will be covered in this post:

* Hugo
* AWS S3
* AWS Route53
* AWS Cloudfront
* Circle CI (I probably should consider to migrate to AWS CodeBuild to make 
this list align. :))

# Initialize a Hugo Git Repository

Follow [Hugo Quick Start](https://gohugo.io/getting-started/quick-start/) to
install and set up a new Hugo site folder.

{{<highlight shell>}}
$ brew install hugo
$ hugo new site blog
{{</highlight>}}

Initialize the folder as a git repository and associate it with a remote
GitHub repository.

{{<highlight shell>}}
$ cd blog
$ git init
$ git remote add origin https://github.com/xxx/blog.git
{{</highlight>}}

Now you can manage your posts in Hugo with Git.

# Setup AWS S3 Bucket

Go to your AWS web console and create a S3 bucket. Configurate the bucket
a bit as follows:

* Enable the **Static website hosting** in the **Properties** tab of the bucket
and specify an index page, as most websites do.

![image](/img/s3-properties-static-hosting.png)

* Make the bucket public accessible by enable list objects permission for everyone
in **Permissions** tab.

![image](/img/s3-permissions-public-access.png)

Now you can build your new create hugo site and upload files to the bucket by
[AWS Command Line Interface](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html) (follow the link to install and config). 

{{<highlight shell>}}
$ cd blog
// build the hugo site
$ hugo
// sync files to S3 bucket
$ aws s3 sync public s3://<your bucket name> --region=us-west-1 --delete  
{{</highlight>}}

By now you should be able to visit your site via the bucket's public link.

# Serve Your Site

To serve your site in a professional way, you better to bind it with a domain
and serve the site with CDN. Now it's time for *AWS Route 53* and *AWS Cloudfront*
come to play. (Assuming you already registered a domain on Route 53.)

## Configure *AWS Cloudfront*

* Create a new web distribution, which points to the S3 bucket you have
just created.

![image](/img/cloudfront-create-distribution.png)

* Use a custom SSL certificate for the domain you are going to bind.

![image](/img/cloudfront-custom-ssl-certificate.png)

Other than these two items, you don't need to change any default value for the distribution
settings. Wait for a couple of minutes to let the new create distribution apply.
Then instead of visiting the S3 bucket public url, you can visit the shorter
cloudfront url (like `https://d3mrg4y7l7xq8t.cloudfront.net`) via https.

## Configure *AWS Route 53*

Create a new **ALIAS** record set and target to the cloudfront distribution url.

![image](/img/route53-record-set.png)

Then you are done with setting up your site. You should be able to visit your site
via https in a minute.

# Auto Deployment to S3

Till now, you can serve your site on AWS S3 fairly well, except that whenever you
make any changes with git, you have to additionally build and sync files manually.

These additional chore work can be easily delegated to continue integration tool,
like Circle CI used in here. I choose Circle CI mostly because it's free and
personal familiarity with it.

* Setup AWS integration with Circle CI following [this simple tutorial](https://circleci.com/docs/1.0/continuous-deployment-with-amazon-s3/)

* Create a `.circleci` folder and add a file `config.yml` in it with the following 
content:

{{<highlight shell>}}
version: 2
jobs:
  build:
    docker:
      - image: rabidgremlin/hugo-s3
    steps:
      - checkout
      - run:
          name: Checkout Theme
          command: git submodule update --init --recursive
      - run:
          name: Build Site 
          command: hugo && ls -al ./public 
      - deploy:
          name: Deploy to S3
          command: aws s3 sync public s3://mengwei.me --region=us-west-1 --delete

{{</highlight>}}

The file is very straightforward that it checks out a docker image `rabidgremlin/hugo-s3`
with Hugo and AWS CLI installed, checkout hugo theme, build the site and then
sync the generated files with S3 bucket.

* As the final step, import the GitHub repository into Circle CI. Now whenever
you made a new push to the repository, it will trigger a new build in Circle CI.
As long as the build finished successfully, your site gets updated.

Now with all these setups, publishing your posts is just as easy as committing your
code.