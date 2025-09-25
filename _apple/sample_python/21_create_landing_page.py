# Copyright 2025 Apple, Inc.
# All Rights Reserved.

from flask import Flask, render_template, request, redirect

app = Flask(__name__)

@app.route("/landingPage", methods=['GET'])
def landing_page():

    # Define defaults
    id_which = 123
    name = "Jim's Coffee Shop"
    logo = "logo.jpg"     # Relative location to image

    # Parse arguments
    # !!! In production, do a security filter and safe encode
    args_list = request.args
    for pair in args_list:
        val = args_list[pair]
        print("%s: %s" % (pair, val))
        if pair == "id":
            id_which = val
        if pair == "name":
            name = val
        if pair == "logo":
            logo = val

    return render_template("landingPage.html", id=id_which, name=name, logo=logo)


@app.route("/landingPage_handle", methods=['POST'])
def form_handler():
    args_list = request.form.to_dict()
    for pair in args_list:
        val = args_list[pair]
        if pair != "userPassword":
            print("SYSTEM: Save to database, %s: %s" % (pair, val))

    return redirect("/landingPage_done", code=302)


@app.route("/landingPage_done", methods=['GET'])
def page_done():
    return "Done!"


app.run(host='0.0.0.0', port=8003)
