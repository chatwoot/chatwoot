# Copyright 2025 Apple, Inc.
# All Rights Reserved.

from flask import Flask

app = Flask(__name__)


@app.route("/message", methods=["POST"])
def receive_message():
    print("Just received a message!")
    return "ok"


app.run(host="0.0.0.0", port=8003)

# Expected output:
# Just received a message!
# Just received a message!

# By default you will at least receive 2 messages. One is for typing start, and the other is for the actual message.
