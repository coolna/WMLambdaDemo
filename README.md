Infrastructure as code (IaC) for a simple web application that runs on AWS Lambda which prints the request header, method, and body.

The application is intergrated with CI/CD using simple GitHub actions, which takes the code from the repoistory to the deployment environment.

The web app is written in python which just replies the method, header and body of the request. The zip file with the pythonfile is copied to the s3 bucket and fed to lambda function. The code creates an api gateway with "any" method and proxy, which is integrated to lambda function. So any query send to the gateway is routed to the lambda and we get the desired output.

For CI/CD, we have 2 branches staging and main. As name implies we do the development in staging and deploy the code to environment when we merge the code to main. The workflows are configured in such a way that we do the terraform plan in the staging branch and terraform apply on the main branch. we can make sure that the code changes made in staging creates the intended changes by looking at the plan output. example : Plan: 13 to add, 0 to change, 0 to destroy.

We can add additional tests w.r.t the functionality of the webserver. We can also actually deploy the code in a test stack and conduct the tests also destroy the test environment after the validation. For simplicity i have just added the plan. We need to make sure that the CI in staging is working as expected before we merge it to master.

When we merge the code to main, the workflow will do terraform apply. This will deploy the code to the environment. We can get the base url from the CI output and try out the api.

Example:

Apply complete! Resources: 13 added, 0 changed, 0 destroyed.

Outputs: base_url = "https://232qmvzla2.execute-api.eu-central-1.amazonaws.com/test"

Testing:

$ curl -XGET https://232qmvzla2.execute-api.eu-central-1.amazonaws.com/test --header "Content-Type: application/json" --data '{"username":"xyz","password":"xyz"}' Hello from lambda land !!, here are the details of your request: Method is : GET headers is : {'accept': '/', 'content-type': 'application/json', 'Host': '232qmvzla2.execute-api.eu-central-1.amazonaws.com', 'User-Agent': 'curl/7.68.0', 'X-Amzn-Trace-Id': 'Root=1-618a8860-5aee45bc2288a7c60e8433e6', 'X-Forwarded-For': '149.224.41.60', 'X-Forwarded-Port': '443', 'X-Forwarded-Proto': 'https'} Body is : {"username":"xyz","password":"xyz"}

$ curl https://232qmvzla2.execute-api.eu-central-1.amazonaws.com/test --header "Content-Type: application/json" --data '{"username":"abc","password":"def"}' Hello from lambda land !!, here are the details of your request: Method is : POST headers is : {'accept': '/', 'content-type': 'application/json', 'Host': '232qmvzla2.execute-api.eu-central-1.amazonaws.com', 'User-Agent': 'curl/7.68.0', 'X-Amzn-Trace-Id': 'Root=1-618a896e-73f552de619762846fb73af4', 'X-Forwarded-For': '149.224.41.60', 'X-Forwarded-Port': '443', 'X-Forwarded-Proto': 'https'} Body is : {"username":"abc","password":"def"}

We have created a s3 backend with dynamodb lock so that the terraform state files are taken care via s3 bucket. Also this helps to  collaborate with your team.

