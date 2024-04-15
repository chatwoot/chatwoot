class ClearChatwootLabels < ActiveRecord::Migration[7.0]
  def change
    Label.destroy_all

    labels = ['Autosvar',
              'No action is needed for this intent!',
              'Boka tolk',
              'Kund vill avboka',
              'Frågor om bokning',
              'Tolk vill ha mer uppdrag',
              'Tolk har tekniska problem',
              'Tolkansökan',
              'Kund har tekniska problem - hemsida',
              'Videolänk',
              'Kund vill ändra bokning',
              'Tolk vill avboka',
              'Arvoden',
              'Felaktig rapportering',
              'Tolk vill ha lönespec',
              'Positiv feedback - tolk',
              'Positiva Referenser',
              'Kund har tekniska problem - appen',
              'Arbetsgivarintyg',
              'Försäkringskassaintyg',
              'A-kassaintyg',
              'Nytt lösenord',
              'Vite till tolk',
              'Kundnummer skapat',
              'Tolkat utan uppdrag',
              'Tillsättning',
              'Teckenspråkstolksförmedling',
              'Avvikelse från kund',
              'Avvikelse från tolk',
              'Svar avvikelse kund',
              'Svar avvikelse tolk',
              'Tekniskt fel från oss',
              'Fel av oss',
              'Kund ändrat tid',
              'Tolkbyte',
              'Tack',
              'Boka tolk - mer info',
              'Översättning',
              'Tolkningstid - Kund',
              'Tillsättning - Inväntar återkoppling',
              'Fel e-postadress',
              'Videolänk - bokningsnummer',
              'Tolk vill acceptera',
              'Tolk - Otillgänglig',
              'Kund behöver e-postadress',
              'Riktade hälsosamtal',
              'Översättning till kund',
              'Specifik tolk',
              'Vem är beställaren?',
              'Tolk rapporterar',
              'Tolk - utlägg',
              'Tolk har tekniska problem - app',
              'Rekrytering - Ukrainska tolkar',
              'Sen rapportering',
              'Booking Create']

    objects = []

    labels.each do |label|
      objects << { account_id: 1, title: label, show_on_sidebar: true, description: label, color: Faker::Color.hex_color }
    end

    Label.insert_all(objects)
  end
end
