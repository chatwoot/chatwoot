# ADR 0002: Default Locale Turkish

Status: Accepted
Date: 27.12.2025

## Context
Env tabanli DEFAULT_LOCALE ayari tek basina yeterli degil. Uygulama ve veri katmaninda varsayilan dil en olarak kalabiliyor ve yeni hesaplar ile kullanici arayuzu en ile acilabiliyor.
Locale enum key degerleri sabit degil (ornek: 21=vi, 23=tr), bu nedenle migration TR key degerini LANGUAGES_CONFIG uzerinden hesaplamali.

## Decision
Uygulama default locale degeri `DEFAULT_LOCALE` ortam degiskeni yoksa `tr` olacak sekilde belirlenecek. Hesaplarin default locale degeri ve mevcut veriler tr olacak sekilde migration ile guncellenecek.

## Consequences
- Yeni hesaplarda varsayilan dil Turkce olur.
- Mevcut hesap ve kullanici arayuzu tercihleri en/null ise Turkce'ye cekilir.
- Global bir varsayilan dil standardi olusur, DEFAULT_LOCALE ile degistirilebilir.

## Alternatives Considered
- Sadece `.env` uzerinden DEFAULT_LOCALE ile kontrol etmek.
- Uygulama tarafinda sadece frontend locale degistirmek.
