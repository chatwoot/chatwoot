## 1.10.0 ##
  * Allow Launchy 3.0+.

## 1.9.0 ##
  * Store mail location in `Mail::Message` object (thanks [Jonathan Chan](https://github.com/jonmchan))
  * Drop Ruby 2 support. Support only Ruby 3.0+
  * Remove `nkf` gem dependency.

## 1.8.1 ##
 * Fix duplication of Rails tasks caused by LetterOpener's rake task file. (thanks [zarqman](https://github.com/zarqman))

## 1.8.0 ##
 * Allow configuration of the 'file///' part in Launchy.open path (thanks [
Regis Millet](https://github.com/Kulgar))
 * Enhance 'tmp:clear' task to delete 'tmp/letter_opener' files (thanks [Joaquín Vicente](https://github.com/wacko))
 * Convert mail's subject to UTF-8. (thanks [kuroponzu](https://github.com/kuroponzu))
 * Use proper attachment's filename sanitization so we don't escape Japanese characters.

## 1.7.0 ##
 * Use default configuration in `Message::rendered_messages` (thanks [Krystan HuffMenne
](https://github.com/gitKrystan))
 * Do not use `Rails.root` path if LetterOpener is used outside of Rails (thanks [centrevillage](https://github.com/centrevillage))
 * Allow to set only `Mail#cc`/`Mail#bcc` without `Mail#to`.

## 1.6.0 ##
 * Do not depend on Mail gem to check delivery params.
 * Do not parse and escape url before passing it to Launchy.

## 1.5.0 ##
 * Use proper check for `Rails::Railties` (thanks [Florian Weingarten](https://github.com/fw42))
 * Add a shim for the iFrame "srcdoc" attribute (make it work with IE).
 * Do not convert `-` to `_` in attachment file names. (thanks [Steven Harman](https://github.com/stevenharman))
 * Drop Ruby 1.9 support.
 * Escape inline attachment names the same way they are stored in the attachments directory (thanks [Daniel Rikowski](https://github.com/daniel-rikowski))
 * Increase timestamp precision in the mail filename. (thanks [Piotr Usewicz](https://github.com/pusewicz))
 * Add ability to configure location of stored mails. (thanks [Ben](https://github.com/beejamin))
 * Add light version of template for mails that doesn't render any additional styling. (thanks [Ben](https://github.com/beejamin))

## 1.4.1 ##
 * Stop base tag appearing in plain-text previews. (thanks [Coby Chapple](https://github.com/cobyism))

## 1.4.0 ##
 * Add base tag to the iframe so links work with X-Frame-Options set to SAMEORIGIN. (thanks [Jason Tokoph](https://github.com/jtokoph))
 * Check delivery params before rendering an email to match SMTP behaviour.

## 1.3.0 ##

 * Fix message body encoding is observed correctly in QP CTE. (thanks [Mark Dodwell](https://github.com/mkdynamic))
 * Remove fixed width on the mail content. (thanks [weexpectedTHIS](https://github.com/weexpectedTHIS))
 * Render email content in the iframe. Fixes [#98](https://github.com/ryanb/letter_opener/issues/98). (thanks [Jacob Maine](https://github.com/mainej))

## 1.2.0 ##

  * Fix auto_link() which in some cases would return an empty <a> tag for plain text messages. (thanks [Kevin McPhillips](https://github.com/kmcphillips))
  * Update styles. (thanks [Adam Doppelt](https://github.com/gurgeous))

## 1.1.2 ##

  * Show formatted display names in html template (thanks [ClaireMcGinty](https://github.com/ClaireMcGinty))
  * Use `file:///` uri scheme to fix Launchy on Windows.

## 1.1.1 ##

  * Handle cc and bcc as array of emails. (thanks [jordandcarter](https://github.com/jordandcarter))
  * Use `file://` uri scheme since Launcy can't open escaped URL without it. (thanks [Adrian2112](https://github.com/Adrian2112))
  * Update Launchy dependency to `~> 2.2` (thanks [JeanMertz](https://github.com/JeanMertz))
  * Change all nonword chars in filename of attachment to underscore so
    it can be saved on all platforms. (thanks [phallstrom](https://github.com/phallstrom))

## 1.1.0 ##

  * Update Launchy dependency to `~> 2.2.0` (thanks [webdevotion](https://github.com/webdevotion))
  * Handle `sender` field (thanks [sjtipton](https://github.com/sjtipton))
  * Show subject only if it's present (thanks [jadehyper](https://github.com/jadehyper))
  * Show subject as title of web page (thanks [statique](https://github.com/statique))

## 1.0.0 ##

  * Attachment Support (thanks [David Cornu](https://github.com/davidcornu))
  * Escape HTML in subject and other fields
  * Raise an exception if the :location option is not present instead of using a default
  * Open rich version by default (thanks [Damir](https://github.com/sidonath))
  * Override margin on dt and dd elements in CSS (thanks [Edgars Beigarts](https://github.com/ebeigarts))
  * Autolink URLs in plain version (thanks [Matt Burke](https://github.com/spraints))

## 0.1.0 ##

  * From and To show name and Email when specified
  * Fix bug when letter_opener couldn't open email in Windows
  * Handle spaces in the application path (thanks [Mike Boone](https://github.com/boone))
  * As letter_opener doesn't work with Launchy < 2.0.4 let's depend on >= 2.0.4 (thanks [Samnang Chhun](https://github.com/samnang))
  * Handle `reply_to` field (thanks [Wes Gibbs](https://github.com/wgibbs))
  * Set the charset in email preview (thanks [Bruno Michel](https://github.com/nono))

## 0.0.2 ##

  * Fixing launchy requirement (thanks [Bruno Michel](https://github.com/nono))

## 0.0.1 ##

  * Initial release
