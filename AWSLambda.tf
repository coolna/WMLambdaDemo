#Zip the fucntion to be run at function App
data "archive_file" "init" {
    type = "zip"
    source_file = "${path.module}/Project/handler.py"
    output_path = "${path.module}/handler.zip"
}

#s3 bucket demobucket
resource "aws_s3_bucket" "wmlambdademoapibucket" {
    bucket = "wmlambdademoapibucket"
    acl = "private"

    tags = {
      "Name" = "wmlambdademoapibucket"
    }
}

#upload zip file to s3 bucket
resource "aws_s3_bucket_object" "object" {
    bucket = aws_s3_bucket.wmlambdademoapibucket.id
    key = "handler.zip"
    source = "${path.module}/handler.zip"  
}

#IAM role for lambda
resource "aws_iam_role" "lambda_role" {
    name = "lambda_role"
    assume_role_policy = file("Project/lambda_assume_role.json")
}

#IAM policy for lambda
resource "aws_iam_role_policy" "lambda_policy" {
    name = "lambda_policy"
    role = aws_iam_role.lambda_role.id
    policy = file("Project/lambda_policy.json")
  
}

resource "aws_lambda_function" "myLambda" {
   function_name = "handler"
   s3_bucket = aws_s3_bucket.wmlambdademoapibucket.id
   s3_key    = "handler.zip"
   handler = "handler.lambda_handler"
   runtime = "python3.6"
   role = aws_iam_role.lambda_role.arn
}

resource "aws_api_gateway_rest_api" "apiLambda" {
  name        = "myAPI"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
  
}

resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   parent_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxyMethod" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_method.proxyMethod.resource_id
   http_method = aws_api_gateway_method.proxyMethod.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.myLambda.invoke_arn
}




resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.apiLambda.id
   resource_id   = aws_api_gateway_rest_api.apiLambda.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.myLambda.invoke_arn
}


resource "aws_api_gateway_deployment" "apideploy" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.apiLambda.id
   stage_name  = "test"
}


resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.myLambda.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.apiLambda.execution_arn}/*/*"
}


output "base_url" {
  value = aws_api_gateway_deployment.apideploy.invoke_url
}
