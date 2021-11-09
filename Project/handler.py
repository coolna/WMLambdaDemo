from __future__ import print_function

import json

print('Loading function')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    print("headers = " + str(event['headers']))
    print("body = " + event['body'])

    return {
        'statusCode': '200',
        'body': "Hello from lambda land !!, here are the details of your request:\nMethod is : " + event['httpMethod'] + "\nheaders is : " + str(event['headers']) + "\nBody is : " + event['body'],
        'headers': {
            'Content-Type': 'application/json'

        }
    }