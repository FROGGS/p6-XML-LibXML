use v6;

use NativeCall;
use XML::LibXML::Parser;

class XML::LibXML is XML::LibXML::Parser;

method parser-version() {
    my $ver = cglobal('libxml2', 'xmlParserVersion', Str);
    Version.new($ver.match(/ (.)? (..)+ $/).list.join: '.')
}
