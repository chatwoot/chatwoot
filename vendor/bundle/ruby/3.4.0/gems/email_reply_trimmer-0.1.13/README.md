# Discourse Email Reply Trimmer [![Build Status](https://api.travis-ci.org/discourse/email_reply_trimmer.svg?branch=master)](https://travis-ci.org/discourse/email_reply_trimmer)

EmailReplyTrimmer is a small library to trim replies from plain text email.

## Usage

To trim replies:

`trimmed_body = EmailReplyTrimmer.trim(email_body)`

## Installation

Get it from [GitHub](https://github.com/discourse/email_reply_trimmer).

Run `rake` to run the tests.

## Inspirations

 - [GitHub's Email Reply Parser](https://github.com/github/email_reply_parser)
 - [MailGun's Talon](https://github.com/mailgun/talon)
 - [Vitor R. Carvalho's Learning to Extract Signature and Reply Lines from Email](http://www.cs.cmu.edu/~vitor/papers/sigFilePaper_finalversion.pdf)
