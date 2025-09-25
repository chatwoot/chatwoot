# Copyright 2025 Apple, Inc.
# All Rights Reserved.

import base64
import gzip
import json
import jwt
import requests

def linkedIn_collect_token_by_code():
    # Enter the code here received in your MSP SERVER ENDPOINT CALLBACK
    code = ""

    url = "https://www.linkedin.com/oauth/v2/accessToken"
    grant_type = "authorization_code"

    # CLIENT IDENTIFIER in Register = <client-identifier-from-your-linkedin-app>
    client_id = "<client-id-from-your-linkedin-app>"
    client_secret = "<client-secret-from-your-linkedin-app>"
    redirect_uri = '<YOUR MSP SERVER ENDPOINT CALLBACK>'

    request_data = {
        "grant_type" : grant_type,
        "code" : code,
        "redirect_uri": redirect_uri,
        "client_id": client_id,
        "client_secret": client_secret
    }

    # Get user's name
    headers = {
        "Content-Type": "application/x-www-form-urlencoded"
    }

    response = requests.post(
        url,
        data = request_data,
        headers = headers,
        timeout = 30
    )

    try:
        jcontent = json.loads(response.content)
        token = jcontent["access_token"]
        linkedIn_collect_user_info_by_token(token)
    except ValueError:
        print("SYSTEM: No JSON object could be found using decrypted token.")
        return None
    except:
        print(("SYSTEM: Endpoint %s taking too long to repond" % url))
        return None
    

def linkedIn_collect_user_info_by_token(token):
    try:
        url = "https://api.linkedin.com/v2/userinfo"
        headers = {
            "Authorization": "Bearer %s" % token
        }

        response = requests.get(
            url,
            headers = headers,
            timeout = 30
        )
        user_info = json.loads(response.content)
        return user_info
    
    except ValueError:
        print("SYSTEM: No JSON object could be found using decrypted token.")
        return None
    except:
        print(("SYSTEM: Endpoint %s taking too long to repond" % url))
        return None


if __name__ == "__main__":
    linkedIn_collect_token_by_code()

