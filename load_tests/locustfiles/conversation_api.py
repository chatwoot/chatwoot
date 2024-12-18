from locust import HttpUser, task
import uuid 
import names
import time
import json
from essential_generators import DocumentGenerator
from common.config import env
from decouple import config  # Para carregar variáveis do .env

def create_contact(self):
  print("Creating Contact")
  print("")
  name = names.get_full_name()
  email =  str(uuid.uuid1()) + "@xyc.com"
  payload = {'inbox_id': self.inbox_id, 'name': name, email: email }
  headers = {'api_access_token': self.api_access_token, 'Content-type': 'application/json'}
  response = self.client.post("/api/v1/accounts/"+self.account_id+"/contacts", 
                        data=json.dumps(payload),
                        headers=headers)
  if response.status_code == 200:
    json_response_dict = response.json()
    return str(json_response_dict['payload']['contact_inbox']['source_id'])
  else:
    try:
      print("response status code is: ", response.status_code)
      print("response body is: ", response.json())
      raise Exception("Contact Creation Failed")
    except Exception:
      raise Exception("Contact Creation Failed")

def create_conversation(self):
  print("Creating Conversation")
  payload = {'source_id':self.contact_source_id }
  headers = {'api_access_token': self.api_access_token, 'Content-type': 'application/json'}
  response = self.client.post("/api/v1/accounts/"+self.account_id+"/conversations", 
                        data=json.dumps(payload),
                        headers=headers)
  if response.status_code == 200:
    json_response_dict = response.json()
    return str(json_response_dict['id'])
  else:
    try:
      print("response status code is: ", response.status_code)
      print("response body is: ", response.json())
      raise Exception("Conversation Creation Failed")
    except Exception:
      raise Exception("Conversation Creation Failed")

def create_message(self):
  gen = DocumentGenerator()
  print("Creating Message")
  payload = {'content': gen.sentence(), "message_type": "incoming" }
  headers = {'api_access_token': self.api_access_token, 'Content-type': 'application/json'}
  response = self.client.post("/api/v1/accounts/"+self.account_id+"/conversations/"+self.converation_id+"/messages", 
                        data=json.dumps(payload),
                        headers=headers)
  if response.status_code == 200:
    json_response_dict = response.json()
    return str(json_response_dict['id'])
  else:
    try:
      print("response status code is: ", response.status_code)
      print("response body is: ", response.json())
      raise Exception("Message Creation Failed")
    except Exception:
      raise Exception("Message Creation Failed")


class ConversationAPIBehavior(HttpUser):

  def on_start(self):
    print("Interacting with the API")
    print(env.str("API_ACCESS_TOKEN"))
    self.api_access_token = env.str("API_ACCESS_TOKEN")
    self.account_id = env.str("ACCOUNT_ID")
    self.inbox_id = env.str("INBOX_ID")

  @task
  def interact_with_conversation_api(self):
    self.contact_source_id = create_contact(self)
    self.converation_id = create_conversation(self)
    self.create_message = create_message(self)
      
    