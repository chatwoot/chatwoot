module Regexp::Syntax
  module Token
    module UnicodeProperty
      all = proc { |name| constants.grep(/#{name}/).flat_map(&method(:const_get)) }

      CharType_V1_9_0 = %i[alnum alpha ascii blank cntrl digit graph
                           lower print punct space upper word xdigit]

      CharType_V2_5_0 = %i[xposixpunct]

      POSIX = %i[any assigned newline]

      module Category
        Letter        = %i[letter uppercase_letter lowercase_letter
                           titlecase_letter modifier_letter other_letter]

        Mark          = %i[mark nonspacing_mark spacing_mark
                           enclosing_mark]

        Number        = %i[number decimal_number letter_number
                           other_number]

        Punctuation   = %i[punctuation connector_punctuation dash_punctuation
                           open_punctuation close_punctuation initial_punctuation
                           final_punctuation other_punctuation]

        Symbol        = %i[symbol math_symbol currency_symbol
                           modifier_symbol other_symbol]

        Separator     = %i[separator space_separator line_separator
                           paragraph_separator]

        Codepoint     = %i[other control format
                           surrogate private_use unassigned]

        All = Letter + Mark + Number + Punctuation +
              Symbol + Separator + Codepoint
      end

      Age_V1_9_3 = %i[age=1.1 age=2.0 age=2.1 age=3.0 age=3.1
                      age=3.2 age=4.0 age=4.1 age=5.0 age=5.1
                      age=5.2 age=6.0]

      Age_V2_0_0 = %i[age=6.1]

      Age_V2_2_0 = %i[age=6.2 age=6.3 age=7.0]

      Age_V2_3_0 = %i[age=8.0]

      Age_V2_4_0 = %i[age=9.0]

      Age_V2_5_0 = %i[age=10.0]

      Age_V2_6_0 = %i[age=11.0]

      Age_V2_6_2 = %i[age=12.0]

      Age_V2_6_3 = %i[age=12.1]

      Age_V3_1_0 = %i[age=13.0]

      Age_V3_2_0 = %i[age=14.0 age=15.0]

      Age = all[:Age_V]

      Derived_V1_9_0 = %i[
        ascii_hex_digit
        alphabetic
        cased
        changes_when_casefolded
        changes_when_casemapped
        changes_when_lowercased
        changes_when_titlecased
        changes_when_uppercased
        case_ignorable
        bidi_control
        dash
        deprecated
        default_ignorable_code_point
        diacritic
        extender
        grapheme_base
        grapheme_extend
        grapheme_link
        hex_digit
        hyphen
        id_continue
        ideographic
        id_start
        ids_binary_operator
        ids_trinary_operator
        join_control
        logical_order_exception
        lowercase
        math
        noncharacter_code_point
        other_alphabetic
        other_default_ignorable_code_point
        other_grapheme_extend
        other_id_continue
        other_id_start
        other_lowercase
        other_math
        other_uppercase
        pattern_syntax
        pattern_white_space
        quotation_mark
        radical
        sentence_terminal
        soft_dotted
        terminal_punctuation
        unified_ideograph
        uppercase
        variation_selector
        white_space
        xid_start
        xid_continue
      ]

      Derived_V2_0_0 = %i[
        cased_letter
        combining_mark
      ]

      Derived_V2_4_0 = %i[
        prepended_concatenation_mark
      ]

      Derived_V2_5_0 = %i[
        regional_indicator
      ]

      Derived = all[:Derived_V]

      Script_V1_9_0 = %i[
        arabic
        imperial_aramaic
        armenian
        avestan
        balinese
        bamum
        bengali
        bopomofo
        braille
        buginese
        buhid
        canadian_aboriginal
        carian
        cham
        cherokee
        coptic
        cypriot
        cyrillic
        devanagari
        deseret
        egyptian_hieroglyphs
        ethiopic
        georgian
        glagolitic
        gothic
        greek
        gujarati
        gurmukhi
        hangul
        han
        hanunoo
        hebrew
        hiragana
        old_italic
        javanese
        kayah_li
        katakana
        kharoshthi
        khmer
        kannada
        kaithi
        tai_tham
        lao
        latin
        lepcha
        limbu
        linear_b
        lisu
        lycian
        lydian
        malayalam
        mongolian
        meetei_mayek
        myanmar
        nko
        ogham
        ol_chiki
        old_turkic
        oriya
        osmanya
        phags_pa
        inscriptional_pahlavi
        phoenician
        inscriptional_parthian
        rejang
        runic
        samaritan
        old_south_arabian
        saurashtra
        shavian
        sinhala
        sundanese
        syloti_nagri
        syriac
        tagbanwa
        tai_le
        new_tai_lue
        tamil
        tai_viet
        telugu
        tifinagh
        tagalog
        thaana
        thai
        tibetan
        ugaritic
        vai
        old_persian
        cuneiform
        yi
        inherited
        common
        unknown
      ]

      Script_V1_9_3 = %i[
        brahmi
        batak
        mandaic
      ]

      Script_V2_0_0 = %i[
        chakma
        meroitic_cursive
        meroitic_hieroglyphs
        miao
        sharada
        sora_sompeng
        takri
      ]

      Script_V2_2_0 = %i[
        caucasian_albanian
        bassa_vah
        duployan
        elbasan
        grantha
        pahawh_hmong
        khojki
        linear_a
        mahajani
        manichaean
        mende_kikakui
        modi
        mro
        old_north_arabian
        nabataean
        palmyrene
        pau_cin_hau
        old_permic
        psalter_pahlavi
        siddham
        khudawadi
        tirhuta
        warang_citi
      ]

      Script_V2_3_0 = %i[
        ahom
        anatolian_hieroglyphs
        hatran
        multani
        old_hungarian
        signwriting
      ]

      Script_V2_4_0 = %i[
        adlam
        bhaiksuki
        marchen
        newa
        osage
        tangut
      ]

      Script_V2_5_0 = %i[
        masaram_gondi
        nushu
        soyombo
        zanabazar_square
      ]

      Script_V2_6_0 = %i[
        dogra
        gunjala_gondi
        hanifi_rohingya
        makasar
        medefaidrin
        old_sogdian
        sogdian
      ]

      Script_V2_6_2 = %i[
        elymaic
        nandinagari
        nyiakeng_puachue_hmong
        wancho
      ]

      Script_V3_1_0 = %i[
        chorasmian
        dives_akuru
        khitan_small_script
        yezidi
      ]

      Script_V3_2_0 = %i[
        cypro_minoan
        kawi
        nag_mundari
        old_uyghur
        tangsa
        toto
        vithkuqi
      ]

      Script = all[:Script_V]

      UnicodeBlock_V1_9_0 = %i[
        in_alphabetic_presentation_forms
        in_arabic
        in_armenian
        in_arrows
        in_basic_latin
        in_bengali
        in_block_elements
        in_bopomofo_extended
        in_bopomofo
        in_box_drawing
        in_braille_patterns
        in_buhid
        in_cjk_compatibility_forms
        in_cjk_compatibility_ideographs
        in_cjk_compatibility
        in_cjk_radicals_supplement
        in_cjk_symbols_and_punctuation
        in_cjk_unified_ideographs_extension_a
        in_cjk_unified_ideographs
        in_cherokee
        in_combining_diacritical_marks_for_symbols
        in_combining_diacritical_marks
        in_combining_half_marks
        in_control_pictures
        in_currency_symbols
        in_cyrillic_supplement
        in_cyrillic
        in_devanagari
        in_dingbats
        in_enclosed_alphanumerics
        in_enclosed_cjk_letters_and_months
        in_ethiopic
        in_general_punctuation
        in_geometric_shapes
        in_georgian
        in_greek_extended
        in_greek_and_coptic
        in_gujarati
        in_gurmukhi
        in_halfwidth_and_fullwidth_forms
        in_hangul_compatibility_jamo
        in_hangul_jamo
        in_hangul_syllables
        in_hanunoo
        in_hebrew
        in_high_private_use_surrogates
        in_high_surrogates
        in_hiragana
        in_ipa_extensions
        in_ideographic_description_characters
        in_kanbun
        in_kangxi_radicals
        in_kannada
        in_katakana_phonetic_extensions
        in_katakana
        in_khmer_symbols
        in_khmer
        in_lao
        in_latin_extended_additional
        in_letterlike_symbols
        in_limbu
        in_low_surrogates
        in_malayalam
        in_mathematical_operators
        in_miscellaneous_symbols_and_arrows
        in_miscellaneous_symbols
        in_miscellaneous_technical
        in_mongolian
        in_myanmar
        in_number_forms
        in_ogham
        in_optical_character_recognition
        in_oriya
        in_phonetic_extensions
        in_private_use_area
        in_runic
        in_sinhala
        in_small_form_variants
        in_spacing_modifier_letters
        in_specials
        in_superscripts_and_subscripts
        in_supplemental_mathematical_operators
        in_syriac
        in_tagalog
        in_tagbanwa
        in_tai_le
        in_tamil
        in_telugu
        in_thaana
        in_thai
        in_tibetan
        in_unified_canadian_aboriginal_syllabics
        in_variation_selectors
        in_yi_radicals
        in_yi_syllables
        in_yijing_hexagram_symbols
      ]

      UnicodeBlock_V2_0_0 = %i[
        in_aegean_numbers
        in_alchemical_symbols
        in_ancient_greek_musical_notation
        in_ancient_greek_numbers
        in_ancient_symbols
        in_arabic_extended_a
        in_arabic_mathematical_alphabetic_symbols
        in_arabic_presentation_forms_a
        in_arabic_presentation_forms_b
        in_arabic_supplement
        in_avestan
        in_balinese
        in_bamum
        in_bamum_supplement
        in_batak
        in_brahmi
        in_buginese
        in_byzantine_musical_symbols
        in_cjk_compatibility_ideographs_supplement
        in_cjk_strokes
        in_cjk_unified_ideographs_extension_b
        in_cjk_unified_ideographs_extension_c
        in_cjk_unified_ideographs_extension_d
        in_carian
        in_chakma
        in_cham
        in_combining_diacritical_marks_supplement
        in_common_indic_number_forms
        in_coptic
        in_counting_rod_numerals
        in_cuneiform
        in_cuneiform_numbers_and_punctuation
        in_cypriot_syllabary
        in_cyrillic_extended_a
        in_cyrillic_extended_b
        in_deseret
        in_devanagari_extended
        in_domino_tiles
        in_egyptian_hieroglyphs
        in_emoticons
        in_enclosed_alphanumeric_supplement
        in_enclosed_ideographic_supplement
        in_ethiopic_extended
        in_ethiopic_extended_a
        in_ethiopic_supplement
        in_georgian_supplement
        in_glagolitic
        in_gothic
        in_hangul_jamo_extended_a
        in_hangul_jamo_extended_b
        in_imperial_aramaic
        in_inscriptional_pahlavi
        in_inscriptional_parthian
        in_javanese
        in_kaithi
        in_kana_supplement
        in_kayah_li
        in_kharoshthi
        in_latin_1_supplement
        in_latin_extended_a
        in_latin_extended_b
        in_latin_extended_c
        in_latin_extended_d
        in_lepcha
        in_linear_b_ideograms
        in_linear_b_syllabary
        in_lisu
        in_lycian
        in_lydian
        in_mahjong_tiles
        in_mandaic
        in_mathematical_alphanumeric_symbols
        in_meetei_mayek
        in_meetei_mayek_extensions
        in_meroitic_cursive
        in_meroitic_hieroglyphs
        in_miao
        in_miscellaneous_mathematical_symbols_a
        in_miscellaneous_mathematical_symbols_b
        in_miscellaneous_symbols_and_pictographs
        in_modifier_tone_letters
        in_musical_symbols
        in_myanmar_extended_a
        in_nko
        in_new_tai_lue
        in_no_block
        in_ol_chiki
        in_old_italic
        in_old_persian
        in_old_south_arabian
        in_old_turkic
        in_osmanya
        in_phags_pa
        in_phaistos_disc
        in_phoenician
        in_phonetic_extensions_supplement
        in_playing_cards
        in_rejang
        in_rumi_numeral_symbols
        in_samaritan
        in_saurashtra
        in_sharada
        in_shavian
        in_sora_sompeng
        in_sundanese
        in_sundanese_supplement
        in_supplemental_arrows_a
        in_supplemental_arrows_b
        in_supplemental_punctuation
        in_supplementary_private_use_area_a
        in_supplementary_private_use_area_b
        in_syloti_nagri
        in_tags
        in_tai_tham
        in_tai_viet
        in_tai_xuan_jing_symbols
        in_takri
        in_tifinagh
        in_transport_and_map_symbols
        in_ugaritic
        in_unified_canadian_aboriginal_syllabics_extended
        in_vai
        in_variation_selectors_supplement
        in_vedic_extensions
        in_vertical_forms
      ]

      UnicodeBlock_V2_2_0 = %i[
        in_bassa_vah
        in_caucasian_albanian
        in_combining_diacritical_marks_extended
        in_coptic_epact_numbers
        in_duployan
        in_elbasan
        in_geometric_shapes_extended
        in_grantha
        in_khojki
        in_khudawadi
        in_latin_extended_e
        in_linear_a
        in_mahajani
        in_manichaean
        in_mende_kikakui
        in_modi
        in_mro
        in_myanmar_extended_b
        in_nabataean
        in_old_north_arabian
        in_old_permic
        in_ornamental_dingbats
        in_pahawh_hmong
        in_palmyrene
        in_pau_cin_hau
        in_psalter_pahlavi
        in_shorthand_format_controls
        in_siddham
        in_sinhala_archaic_numbers
        in_supplemental_arrows_c
        in_tirhuta
        in_warang_citi
      ]

      UnicodeBlock_V2_3_0 = %i[
        in_ahom
        in_anatolian_hieroglyphs
        in_cjk_unified_ideographs_extension_e
        in_cherokee_supplement
        in_early_dynastic_cuneiform
        in_hatran
        in_multani
        in_old_hungarian
        in_supplemental_symbols_and_pictographs
        in_sutton_signwriting
      ]

      UnicodeBlock_V2_4_0 = %i[
        in_adlam
        in_bhaiksuki
        in_cyrillic_extended_c
        in_glagolitic_supplement
        in_ideographic_symbols_and_punctuation
        in_marchen
        in_mongolian_supplement
        in_newa
        in_osage
        in_tangut
        in_tangut_components
      ]

      UnicodeBlock_V2_5_0 = %i[
        in_cjk_unified_ideographs_extension_f
        in_kana_extended_a
        in_masaram_gondi
        in_nushu
        in_soyombo
        in_syriac_supplement
        in_zanabazar_square
      ]

      UnicodeBlock_V2_6_0 = %i[
        in_chess_symbols
        in_dogra
        in_georgian_extended
        in_gunjala_gondi
        in_hanifi_rohingya
        in_indic_siyaq_numbers
        in_makasar
        in_mayan_numerals
        in_medefaidrin
        in_old_sogdian
        in_sogdian
      ]

      UnicodeBlock_V2_6_2 = %i[
        in_egyptian_hieroglyph_format_controls
        in_elymaic
        in_nandinagari
        in_nyiakeng_puachue_hmong
        in_ottoman_siyaq_numbers
        in_small_kana_extension
        in_symbols_and_pictographs_extended_a
        in_tamil_supplement
        in_wancho
      ]

      UnicodeBlock_V3_1_0 = %i[
        in_chorasmian
        in_cjk_unified_ideographs_extension_g
        in_dives_akuru
        in_khitan_small_script
        in_lisu_supplement
        in_symbols_for_legacy_computing
        in_tangut_supplement
        in_yezidi
      ]

      UnicodeBlock_V3_2_0 = %i[
        in_arabic_extended_b
        in_arabic_extended_c
        in_cjk_unified_ideographs_extension_h
        in_cypro_minoan
        in_cyrillic_extended_d
        in_devanagari_extended_a
        in_ethiopic_extended_b
        in_kaktovik_numerals
        in_kana_extended_b
        in_kawi
        in_latin_extended_f
        in_latin_extended_g
        in_nag_mundari
        in_old_uyghur
        in_tangsa
        in_toto
        in_unified_canadian_aboriginal_syllabics_extended_a
        in_vithkuqi
        in_znamenny_musical_notation
      ]

      UnicodeBlock = all[:UnicodeBlock_V]

      Emoji_V2_5_0 = %i[
        emoji
        emoji_component
        emoji_modifier
        emoji_modifier_base
        emoji_presentation
      ]

      Emoji_V2_6_0 = %i[
        extended_pictographic
      ]

      Enumerated_V2_4_0 = %i[
        grapheme_cluster_break=control
        grapheme_cluster_break=cr
        grapheme_cluster_break=extend
        grapheme_cluster_break=l
        grapheme_cluster_break=lf
        grapheme_cluster_break=lv
        grapheme_cluster_break=lvt
        grapheme_cluster_break=prepend
        grapheme_cluster_break=regional_indicator
        grapheme_cluster_break=spacingmark
        grapheme_cluster_break=t
        grapheme_cluster_break=v
        grapheme_cluster_break=zwj
      ]

      Enumerated = all[:Enumerated_V]

      Emoji = all[:Emoji_V]

      V1_9_0 = Category::All + POSIX + all[:V1_9_0]
      V1_9_3 = all[:V1_9_3]
      V2_0_0 = all[:V2_0_0]
      V2_2_0 = all[:V2_2_0]
      V2_3_0 = all[:V2_3_0]
      V2_4_0 = all[:V2_4_0]
      V2_5_0 = all[:V2_5_0]
      V2_6_0 = all[:V2_6_0]
      V2_6_2 = all[:V2_6_2]
      V2_6_3 = all[:V2_6_3]
      V3_1_0 = all[:V3_1_0]
      V3_2_0 = all[:V3_2_0]

      All = all[/^V\d+_\d+_\d+$/]

      Type = :property
      NonType = :nonproperty
    end

    Map[UnicodeProperty::Type] = UnicodeProperty::All
    Map[UnicodeProperty::NonType] = UnicodeProperty::All

    # alias for symmetry between token symbol and Token module name
    Property = UnicodeProperty
  end
end
