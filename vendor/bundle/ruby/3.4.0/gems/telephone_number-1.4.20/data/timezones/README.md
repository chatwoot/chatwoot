# Timezone Mapper

The timezone mapper allows a likely timezone to be obtained for a given phone
number. The timezone returned is the canonical ID from [CLDR](
http://www.unicode.org/cldr/charts/latest/supplemental/zone_tzid.html), not a
localised name (or any other identifier). For mobile phones which are associated
with particular area codes, it returns the timezone of the area code; it does
not track the user's current location in any way. This could be used to work out
whether it is likely to be a good time to ring a user based on their provided
number.

Code Location:
[java/geocoder/src/com/google/i18n/phonenumbers/PhoneNumberToTimeZonesMapper.java](https://github.com/google/libphonenumber/blob/master/java/geocoder/src/com/google/i18n/phonenumbers/PhoneNumberToTimeZonesMapper.java)

Example usage:

```
PhoneNumberToTimeZonesMapper timeZonesMapper = PhoneNumberToTimeZonesMapper.getInstance();

List<String> timezones = timeZonesMapper.getTimeZonesForNumber(phoneNumber);
```

## Contributing to the timezone metadata

The timezone metadata is auto-generated with few exceptions, so we cannot accept
pull requests. If we have an error please file an issue and we'll see if we can
make a generic fix.

If making fixes in your own fork while you wait for this, build the metadata by
running this command from the root of the repository (assuming you have `ant`
installed):

```
ant -f java/build.xml build-timezones-data
```

Note that, due to our using stable CLDR timezone IDs, we do not change the ID
for an existing timezone when the name of a region or subdivision changes. The
library returns the *ID*, which you may use to get the localised name from CLDR.

See CLDR's [documentation for timezone
translations](http://cldr.unicode.org/translation/timezones). You can also
browse [different languages'
names](http://www.unicode.org/cldr/charts/latest/verify/zones/index.html); for
example, the `Asia/Calcutta` timezone identifier has English names
`Kolkata Time` and `India Standard Time`, and the [English
file](http://www.unicode.org/cldr/charts/latest/verify/zones/en.html) links to
a [view](http://st.unicode.org/cldr-apps/v#/en/SAsia/2dac3ef061238996) with
other regions having the same timezone (including those with different IDs).

Other relevant CLDR data:
*   http://www.unicode.org/cldr/charts/latest/supplemental/zone_tzid.html
*   http://unicode.org/repos/cldr/trunk/common/bcp47/timezone.xml
*   http://unicode.org/repos/cldr/trunk/common/supplemental/metaZones.xml
*   http://unicode.org/repos/cldr/trunk/common/supplemental/windowsZones.xml
