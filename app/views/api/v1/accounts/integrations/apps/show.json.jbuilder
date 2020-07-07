json.id @app.id
json.name @app.name
json.logo @app.logo
json.description @app.description
json.fields @app.fields
json.enabled @app.enabled?(@current_account)
json.button @app.action
