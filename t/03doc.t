use v6;
use Test;

# this test checks the DOM Document interface of XML::LibXML

# it will ONLY test the DOM capabilities as specified in DOM Level3
# XPath tests should be done in another test file

# since all tests are run on a preparsed

plan 55;

use XML::LibXML;
use XML::LibXML::Enums;

{
    # Document Attributes

    my $doc = XML::LibXML::Document.new();
    ok($doc, ' TODO : Add test name');
    is( $doc.encoding, 'utf-8', ' TODO : Add test name');
    is( $doc.version,  v1.0, ' TODO : Add test name' );
    is( $doc.standalone, -1, ' TODO : Add test name' );  # is the value we get for undefined,
                                 # actually the same as 0 but just not set.
    ok( !defined($doc.uri), ' TODO : Add test name');  # should be set by default.
    is( $doc.compression, -1, ' TODO : Add test name' ); # -1 indicates NO compression at all!
                                 # while 0 indicates just no zip compression
                                 # (big difference huh?)

    $doc.encoding = "iso-8859-1";
    is( $doc.encoding, "iso-8859-1", 'Encoding was set.' );

    $doc.version = v12.5;
    is( $doc.version, v12.5, 'Version was set.' );

    $doc.standalone = 1;
    is( $doc.standalone, 1, 'Standalone was set.' );

    $doc.base-uri = "localhost/here.xml";
    is( $doc.uri, "localhost/here.xml", 'URI is set.' );

    my $doc2 = XML::LibXML::Document.new(:version(v1.1), :encoding<iso-8859-2>);
    is( $doc2.encoding, "iso-8859-2", 'doc2 encoding was set.' );
    is( $doc2.version,  "1.1", 'doc2 version was set.' );
    is( $doc2.standalone,  -1, 'doc2 standalone' );
}

{
    # 2. Creating Elements
    my $doc = XML::LibXML::Document.new();
    {
        my $node = $doc.new-doc-fragment();
        ok($node, ' TODO : Add test name');
        is($node.type, XML_DOCUMENT_FRAG_NODE, ' TODO : Add test name');
    }

    _check_created_element($doc, 'foo', 'foo', 'Simple Element');

    {
        # document with encoding
        my $encdoc = XML::LibXML::Document.new( :version<1.0> );
        $encdoc.encoding = "iso-8859-1";

        _check_created_element($encdoc, 'foo', 'foo', 'Encdoc Element creation');
    }

    {
        # namespaced element test
        my $node = $doc.new-elem-ns("foo:bar", "http://kungfoo");
        ok $node,                             'xmlDoc.new-elem-ns';
        is $node.type,      XML_ELEMENT_NODE, 'xmlDoc.new-elem-ns.type';
        is $node.name,      "foo:bar",        'xmlDoc.new-elem-ns.name';
        is $node.ns.name,   "foo",            'xmlDoc.new-elem-ns.ns.name';
        is $node.localname, "bar",            'xmlDoc.new-elem-ns.localname';
        is $node.ns.uri,    "http://kungfoo", 'xmlDoc.new-elem-ns.ns.uri';
    }

    {
        # bad element creation
        for ";", "&", "<><", "/", "1A" -> $name {
            my $f = $doc.new-elem($name);
            ok $f ~~ Failure, "bad element creation '$name'";
        }
    }

    {
        my $node = $doc.new-text( "foo" );
        ok($node, ' TODO : Add test name');
        is($node.type, XML_TEXT_NODE, ' TODO : Add test name' );
        is($node.value, "foo", ' TODO : Add test name' );
    }

    {
        my $node = $doc.new-comment( "foo" );
        ok($node, ' TODO : Add test name');
        is($node.type, XML_COMMENT_NODE, ' TODO : Add test name' );
        is($node.value, "foo", ' TODO : Add test name' );
        is($node.Str, "<!--foo-->", ' TODO : Add test name');
    }

    {
        my $node = $doc.new-cdata-block( "foo" );
        ok($node, ' TODO : Add test name');
        is($node.type, XML_CDATA_SECTION_NODE, ' TODO : Add test name' );
        is($node.value, "foo", ' TODO : Add test name' );
        is($node.Str, "<![CDATA[foo]]>", ' TODO : Add test name');
    }

    # -> Create Attributes
    {
        my $attr = $doc.createAttribute("foo" => "bar");
        ok $attr, ' TODO : Add test name';
        is $attr.type, XML_ATTRIBUTE_NODE, ' TODO : Add test name';
        is $attr.name, "foo", ' TODO : Add test name';
        is $attr.value, "bar", ' TODO : Add test name';
        my $content = $attr.firstChild;
        ok $content, ' TODO : Add test name';
        is $content.type, XML_TEXT_NODE, ' TODO : Add test name';
    }
    #~ {
        #~ # bad attribute creation
        #~ # TEST:$badnames_count=5;
        #~ my @badnames = ( ";", "&", "<><", "/", "1A");

        #~ foreach my $name ( @badnames ) {
            #~ my $node = eval {$doc->createAttribute( $name, "bar" );};
            #~ # TEST*$badnames_count
            #~ ok( !defined($node), ' TODO : Add test name' );
        #~ }

    #~ }
    {
        my $elem = $doc.new-elem('foo');
        my $attr = $doc.new-attr('attr' => 'e & f');
        $elem.push: $attr;
        is($elem.Str, '<foo attr="e &amp; f"/>', ' TODO : Add test name');
        $elem.remove-attr('attr');

        is($elem.Str, '<foo/>', ' TODO : Add test name');
        $attr = $doc.new-attr(:attr2('foo bar baz'));
        $elem.push: $attr;
        is($elem.Str, '<foo attr2="foo bar baz"/>', ' TODO : Add test name');
        $elem.remove-attr('attr2');
    }
    {
        my $attr = $doc.new-attr-ns('attr2' => 'a & b', 'http://foobar.baz');
        ok $attr ~~ Failure,            'xmlDoc.new-attr-ns depends on doc.root';

        my $root  = $doc.new-elem('foo');
        $doc.root = $root;
        $attr     = $doc.new-attr-ns('kung:foo' => 'bar', 'http://kungfoo');
        ok $attr,                       'xmlDoc.new-attr-ns';
        is $attr.ns.name,   "kung",     'xmlDoc.new-attr-ns.ns.name';
        is $attr.name,      "kung:foo", 'xmlDoc.new-attr-ns.name';
        is $attr.localname, "foo",      'xmlDoc.new-attr-ns.localname';
        is $attr.value,     "bar",      'xmlDoc.new-attr-ns.value';

        $attr.value = 'bar&amp;';
        is $attr.value,     'bar&amp;', 'xmlDoc.new-attr-ns.value changed';
    }
    #~ {
        #~ # bad attribute creation
        #~ # TEST:$badnames_count=5;
        #~ my @badnames = ( ";", "&", "<><", "/", "1A");

        #~ foreach my $name ( @badnames ) {
            #~ my $node = eval {$doc->createAttributeNS( undef, $name, "bar" );};
            #~ # TEST*$badnames_count
            #~ ok( (!defined $node), ' TODO : Add test name' );
        #~ }

    #~ }

    #~ # -> Create PIs
    #~ {
        #~ my $pi = $doc->createProcessingInstruction( "foo", "bar" );
        #~ # TEST
        #~ ok($pi, ' TODO : Add test name');
        #~ # TEST
        #~ is($pi->nodeType, XML_PI_NODE, ' TODO : Add test name');
        #~ # TEST
        #~ is($pi->nodeName, "foo", ' TODO : Add test name');
        #~ # TEST
        #~ is($pi->textContent, "bar", ' TODO : Add test name');
        #~ # TEST
        #~ is($pi->getData, "bar", ' TODO : Add test name');
    #~ }

    #~ {
        #~ my $pi = $doc->createProcessingInstruction( "foo" );
        #~ # TEST
        #~ ok($pi, ' TODO : Add test name');
        #~ # TEST
        #~ is($pi->nodeType, XML_PI_NODE, ' TODO : Add test name');
        #~ # TEST
        #~ is($pi->nodeName, "foo", ' TODO : Add test name');
        #~ my $data = $pi->textContent;
        #~ # undef or "" depending on libxml2 version
        #~ # TEST
        #~ ok( is_empty_str($data), ' TODO : Add test name' );
        #~ $data = $pi->getData;
        #~ # TEST
        #~ ok( is_empty_str($data), ' TODO : Add test name' );
        #~ $pi->setData(q(bar&amp;));
        #~ # TEST
        #~ is( $pi->getData, q(bar&amp;), ' TODO : Add test name');
        #~ # TEST
        #~ is($pi->textContent, q(bar&amp;), ' TODO : Add test name');
    #~ }
}

#~ {
    #~ # Document Manipulation
    #~ # -> Document Elements

    #~ my $doc = XML::LibXML::Document->new();
    #~ my $node = $doc->createElement( "foo" );
    #~ $doc->setDocumentElement( $node );
    #~ my $tn = $doc->documentElement;
    #~ # TEST
    #~ ok($tn, ' TODO : Add test name');
    #~ # TEST
    #~ ok($node->isSameNode($tn), ' TODO : Add test name');

    #~ my $node2 = $doc->createElement( "bar" );
    #~ { my $warn;
      #~ eval {
        #~ local $SIG{__WARN__} = sub { $warn = 1 };
        #~ # TEST
        #~ ok( !defined($doc->appendChild($node2)), ' TODO : Add test name' );
      #~ };
      #~ # TEST
      #~ ok(($@ or $warn), ' TODO : Add test name');
    #~ }
    #~ my @cn = $doc->childNodes;
    #~ # TEST
    #~ is( scalar(@cn) , 1, ' TODO : Add test name');
    #~ # TEST
    #~ ok($cn[0]->isSameNode($node), ' TODO : Add test name');

    #~ eval {
      #~ $doc->insertBefore($node2, $node);
    #~ };
    #~ # TEST
    #~ ok ($@, ' TODO : Add test name');
    #~ @cn = $doc->childNodes;
    #~ # TEST
    #~ is( scalar(@cn) , 1, ' TODO : Add test name');
    #~ # TEST
    #~ ok($cn[0]->isSameNode($node), ' TODO : Add test name');

    #~ $doc->removeChild($node);
    #~ @cn = $doc->childNodes;
    #~ # TEST
    #~ is( scalar(@cn) , 0, ' TODO : Add test name');

    #~ for ( 1..2 ) {
        #~ my $nodeA = $doc->createElement( "x" );
        #~ $doc->setDocumentElement( $nodeA );
    #~ }
    #~ # TEST
    #~ ok(1, ' TODO : Add test name'); # must not segfault here :)

    #~ $doc->setDocumentElement( $node2 );
    #~ @cn = $doc->childNodes;
    #~ # TEST
    #~ is( scalar(@cn) , 1, ' TODO : Add test name');
    #~ # TEST
    #~ ok($cn[0]->isSameNode($node2), ' TODO : Add test name');

    #~ my $node3 = $doc->createElementNS( "http://foo", "bar" );
    #~ # TEST
    #~ ok($node3, ' TODO : Add test name');

    #~ # -> Processing Instructions
    #~ {
        #~ my $pi = $doc->createProcessingInstruction( "foo", "bar" );
        #~ $doc->appendChild( $pi );
        #~ @cn = $doc->childNodes;
        #~ # TEST
        #~ ok( $pi->isSameNode($cn[-1]), ' TODO : Add test name' );
        #~ $pi->setData( 'bar="foo"' );
        #~ # TEST
        #~ is( $pi->textContent, 'bar="foo"', ' TODO : Add test name');
        #~ $pi->setData( foo=>"foo" );
        #~ # TEST
        #~ is( $pi->textContent, 'foo="foo"', ' TODO : Add test name');
    #~ }
#~ }

#~ package Stringify;

#~ use overload q[""] => sub { return '<A xmlns:C="xml://D"><C:A>foo<A/>bar</C:A><A><C:B/>X</A>baz</A>'; };

#~ sub new
#~ {
    #~ return bless \(my $x);
#~ }

#~ package main;

#~ {
    #~ # Document Storing
    #~ my $parser = XML::LibXML->new;
    #~ my $doc = $parser->parse_string("<foo>bar</foo>");

    #~ # TEST

    #~ ok( $doc, ' TODO : Add test name' );

    #~ # -> to file handle

    #~ {
        #~ open my $fh, '>', 'example/testrun.xml'
            #~ or die "Cannot open example/testrun.xml for writing - $!.";

        #~ $doc->toFH( $fh );
        #~ $fh->close;
        #~ # TEST
        #~ ok(1, ' TODO : Add test name');
        #~ # now parse the file to check, if succeeded
        #~ my $tdoc = $parser->parse_file( "example/testrun.xml" );
        #~ # TEST
        #~ ok( $tdoc, ' TODO : Add test name' );
        #~ # TEST
        #~ ok( $tdoc->documentElement, ' TODO : Add test name' );
        #~ # TEST
        #~ is( $tdoc->documentElement->nodeName, "foo", ' TODO : Add test name' );
        #~ # TEST
        #~ is( $tdoc->documentElement->textContent, "bar", ' TODO : Add test name' );
        #~ unlink "example/testrun.xml" ;
    #~ }

    #~ # -> to named file
    #~ {
        #~ $doc->toFile( "example/testrun.xml" );
        #~ # TEST
        #~ ok(1, ' TODO : Add test name');
        #~ # now parse the file to check, if succeeded
        #~ my $tdoc = $parser->parse_file( "example/testrun.xml" );
        #~ # TEST
        #~ ok( $tdoc, ' TODO : Add test name' );
        #~ # TEST
        #~ ok( $tdoc->documentElement, ' TODO : Add test name' );
        #~ # TEST
        #~ is( $tdoc->documentElement->nodeName, "foo", ' TODO : Add test name' );
        #~ # TEST
        #~ is( $tdoc->documentElement->textContent, "bar", ' TODO : Add test name' );
        #~ unlink "example/testrun.xml" ;
    #~ }

    #~ # ELEMENT LIKE FUNCTIONS
    #~ {
        #~ my $parser2 = XML::LibXML->new();
        #~ my $string1 = "<A><A><B/></A><A><B/></A></A>";
        #~ my $string2 = '<C:A xmlns:C="xml://D"><C:A><C:B/></C:A><C:A><C:B/></C:A></C:A>';
        #~ my $string3 = '<A xmlns="xml://D"><A><B/></A><A><B/></A></A>';
        #~ my $string4 = '<C:A><C:A><C:B/></C:A><C:A><C:B/></C:A></C:A>';
        #~ my $string5 = '<A xmlns:C="xml://D"><C:A>foo<A/>bar</C:A><A><C:B/>X</A>baz</A>';
        #~ {
            #~ my $doc2 = $parser2->parse_string($string1);
            #~ # TEST
            #~ _count_tag_name($doc2, 'A', 3, q{3 As});
            #~ # TEST
            #~ _count_tag_name($doc2, '*', 5, q{5 elements of all names});

            #~ # TEST
            #~ _count_elements_by_name_ns($doc2, ['*', 'B'], 2,
                #~ '2 Bs of any namespace'
            #~ );

            #~ # TEST
            #~ _count_local_name($doc2, 'A', 3, q{3 A's});

            #~ # TEST
            #~ _count_local_name($doc2, '*', 5, q{5 Sub-elements});
        #~ }
        #~ {
            #~ my $doc2 = $parser2->parse_string($string2);
            #~ # TEST
            #~ _count_tag_name( $doc2, 'C:A', 3, q{C:A count});
            #~ # TEST
            #~ _count_elements_by_name_ns($doc2, [ "xml://D", "A" ], 3,
                #~ q{3 elements of namespace xml://D and A},
            #~ );
            #~ # TEST
            #~ _count_elements_by_name_ns($doc2, ['*', 'A'], 3,
                #~ q{3 Elements A of any namespace}
            #~ );
            #~ # TEST
            #~ _count_local_name($doc2, 'A', 3, q{3 As});
        #~ }
        #~ {
            #~ my $doc2 = $parser2->parse_string($string3);
            #~ # TEST
            #~ _count_elements_by_name_ns($doc2, ["xml://D", "A"], 3,
                #~ q{3 Elements A of any namespace}
            #~ );
            #~ # TEST
            #~ _count_local_name($doc2, 'A', 3, q{3 As});
        #~ }
#~ =begin taken_out
        #~ # This was taken out because the XML uses an undefined namespace.
        #~ # I don't know why this test was introduced in the first place,
        #~ # but it fails now
        #~ #
        #~ # This test fails in this bug report -
        #~ # https://rt.cpan.org/Ticket/Display.html?id=75403
        #~ # -- Shlomi Fish
        #~ {
            #~ $parser2->recover(1);
            #~ local $SIG{'__WARN__'} = sub {
                  #~ print "warning caught: @_\n";
            #~ };
            #~ # my $doc2 = $parser2->parse_string($string4);
            #~ #-TEST
            #~ # _count_local_name( $doc2, 'A', 3, q{3 As});
        #~ }
#~ =end taken_out

#~ =cut
    #~ # TEST:$count=3;
    #~ # Also test that we can parse from scalar references:
    #~ # See RT #64051 ( https://rt.cpan.org/Ticket/Display.html?id=64051 )
    #~ # Also test that we can parse from references to scalars with
    #~ # overloaded strings:
    #~ # See RT #77864 ( https://rt.cpan.org/Public/Bug/Display.html?id=77864 )

        #~ my $obj = Stringify->new;

        #~ foreach my $input ( $string5, (\$string5), $obj )
        #~ {
            #~ my $doc2 = $parser2->parse_string($input);
            #~ # TEST*$count
            #~ _count_tag_name($doc2, 'C:A', 1, q{3 C:As});
            #~ # TEST*$count
            #~ _count_tag_name($doc2, 'A', 3, q{3 As});
            #~ # TEST*$count
            #~ _count_elements_by_name_ns($doc2, ["*", "A"], 4,
                #~ q{4 Elements of A of any namespace}
            #~ );
            #~ # TEST*$count
            #~ _count_elements_by_name_ns($doc2, ['*', '*'], 5,
                #~ q{4 Elements of any namespace},
            #~ );
            #~ # TEST*$count
            #~ _count_elements_by_name_ns( $doc2, ["xml://D", "*" ], 2,
                #~ q{2 elements of any name in D}
            #~ );

            #~ my $A = $doc2->getDocumentElement;
            #~ # TEST*$count
            #~ _count_children_by_name($A, 'A', 1, q{1 A});
            #~ # TEST*$count
            #~ _count_children_by_name($A, 'C:A', 1, q{C:A});
            #~ # TEST*$count
            #~ _count_children_by_name($A, 'C:B', 0, q{No C:B children});
            #~ # TEST*$count
            #~ _count_children_by_name($A, "*", 2, q{2 Childern in $A in total});
            #~ # TEST*$count
            #~ _count_children_by_name_ns($A, ['*', 'A'], 2,
                #~ q{2 As of any namespace});
            #~ # TEST*$count
            #~ _count_children_by_name_ns($A, [ "xml://D", "*" ], 1,
                #~ q{1 Child of D},
            #~ );
            #~ # TEST*$count
            #~ _count_children_by_name_ns($A, [ "*", "*" ], 2,
                #~ q{2 Children in total},
            #~ );
            #~ # TEST*$count
            #~ _count_children_by_local_name($A, 'A', 2, q{2 As});
        #~ }
    #~ }
#~ }

#~ {
    #~ # Bug fixes (to be used with valgrind)
    #~ {
       #~ my $doc=XML::LibXML->createDocument(); # create a doc
       #~ my $x=$doc->createPI(foo=>"bar");      # create a PI
       #~ undef $doc;                            # should not free
       #~ undef $x;                              # free the PI
       #~ # TEST
       #~ ok(1, ' TODO : Add test name');
    #~ }
    #~ {
       #~ my $doc=XML::LibXML->createDocument(); # create a doc
       #~ my $x=$doc->createAttribute(foo=>"bar"); # create an attribute
       #~ undef $doc;                            # should not free
       #~ undef $x;                              # free the attribute
       #~ # TEST
       #~ ok(1, ' TODO : Add test name');
    #~ }
    #~ {
       #~ my $doc=XML::LibXML->createDocument(); # create a doc
       #~ my $x=$doc->createAttributeNS(undef,foo=>"bar"); # create an attribute
       #~ undef $doc;                            # should not free
       #~ undef $x;                              # free the attribute
       #~ # TEST
       #~ ok(1, ' TODO : Add test name');
    #~ }
    #~ {
       #~ my $doc=XML::LibXML->new->parse_string('<foo xmlns:x="http://foo.bar"/>');
       #~ my $x=$doc->createAttributeNS('http://foo.bar','x:foo'=>"bar"); # create an attribute
       #~ undef $doc;                            # should not free
       #~ undef $x;                              # free the attribute
       #~ # TEST
       #~ ok(1, ' TODO : Add test name');
    #~ }
    #~ {
      #~ # rt.cpan.org #30610
      #~ # valgrind this
      #~ my $object=XML::LibXML::Element->new( 'object' );
      #~ my $xml = qq(<?xml version="1.0" encoding="UTF-8"?>\n<lom/>);
      #~ my $lom_doc=XML::LibXML->new->parse_string($xml);
      #~ my $lom_root=$lom_doc->getDocumentElement();
      #~ $object->appendChild( $lom_root );
      #~ # TEST
      #~ ok(!defined($object->firstChild->ownerDocument), ' TODO : Add test name');
    #~ }
#~ }


#~ {
  #~ my $xml = q{<?xml version="1.0" encoding="UTF-8"?>
#~ <test/>
#~ };
  #~ my $out = q{<?xml version="1.0"?>
#~ <test/>
#~ };
  #~ my $dom = XML::LibXML->new->parse_string($xml);
  #~ # TEST
  #~ is($dom->getEncoding, "UTF-8", ' TODO : Add test name');
  #~ $dom->setEncoding();
  #~ # TEST
  #~ is($dom->getEncoding, undef, ' TODO : Add test name');
  #~ # TEST
  #~ is($dom->toString, $out, ' TODO : Add test name');
#~ }

#~ # the following tests were added for #33810
#~ SKIP:
#~ {
    #~ if (! eval { require Encode; })
    #~ {
        #~ skip "Encoding related tests require Encode", (3*8);
    #~ }
    #~ # TEST:$num_encs=3;
    #~ # The count.
    #~ # TEST:$c=0;
    #~ for my $enc (qw(UTF-16 UTF-16LE UTF-16BE)) {
        #~ my $xml = Encode::encode($enc,qq{<?xml version="1.0" encoding="$enc"?>
            #~ <test foo="bar"/>
            #~ });
        #~ my $dom = XML::LibXML->new->parse_string($xml);
        #~ # TEST:$c++;
        #~ is($dom->getEncoding,$enc, ' TODO : Add test name');
        #~ # TEST:$c++;
        #~ is($dom->actualEncoding,$enc, ' TODO : Add test name');
        #~ # TEST:$c++;
        #~ is($dom->getDocumentElement->getAttribute('foo'),'bar', ' TODO : Add test name');
        #~ # TEST:$c++;
        #~ is($dom->getDocumentElement->getAttribute(Encode::encode('UTF-16','foo')), 'bar', ' TODO : Add test name');
        #~ # TEST:$c++;
        #~ is($dom->getDocumentElement->getAttribute(Encode::encode($enc,'foo')), 'bar', ' TODO : Add test name');
        #~ my $exp_enc = $enc eq 'UTF-16' ? 'UTF-16LE' : $enc;
        #~ # TEST:$c++;
        #~ is($dom->getDocumentElement->getAttribute('foo',1), Encode::encode($exp_enc,'bar'), ' TODO : Add test name');
        #~ # TEST:$c++;
        #~ is($dom->getDocumentElement->getAttribute(Encode::encode('UTF-16','foo'),1), Encode::encode($exp_enc,'bar'), ' TODO : Add test name');
        #~ # TEST:$c++;
        #~ is($dom->getDocumentElement->getAttribute(Encode::encode($enc,'foo'),1), Encode::encode($exp_enc,'bar'), ' TODO : Add test name');
    #~ }
    #~ # TEST*$num_encs*$c
#~ }

#~ sub is_empty_str
#~ {
    #~ my $s = shift;
    #~ return (!defined($s) or (length($s) == 0));
#~ }

sub _check_created_element($doc, $given_name, $name, $blurb) {
    subtest {
        my $node = $doc.new-elem($given_name);
        ok($node,                        "node was initialised");
        is($node.type, XML_ELEMENT_NODE, "node is an element node");
        is($node.name, $name,            "node has the right name.");
    }, $blurb;
}

#~ sub _multi_arg_generic_count
#~ {
    #~ local $Test::Builder::Level = $Test::Builder::Level + 1;

    #~ my ($doc, $method, $params) = @_;

    #~ my ($meth_params, $want_count, $blurb) = @$params;

    #~ my @elems = $doc->$method( @$meth_params );

    #~ return is (scalar(@elems), $want_count, $blurb);
#~ }

#~ sub _generic_count
#~ {
    #~ local $Test::Builder::Level = $Test::Builder::Level + 1;

    #~ my ($doc, $method, $params) = @_;

    #~ my ($name, $want_count, $blurb) = @$params;

    #~ return _multi_arg_generic_count(
        #~ $doc, $method, [[$name], $want_count, $blurb, ],
    #~ );
#~ }

#~ sub _count_local_name
#~ {
    #~ local $Test::Builder::Level = $Test::Builder::Level + 1;
    #~ my $doc = shift;

    #~ return _generic_count($doc, 'getElementsByLocalName', [@_]);
#~ }

#~ sub _count_tag_name
#~ {
    #~ local $Test::Builder::Level = $Test::Builder::Level + 1;
    #~ my $doc = shift;

    #~ return _generic_count($doc, 'getElementsByTagName', [@_]);
#~ }

#~ sub _count_children_by_local_name
#~ {
    #~ local $Test::Builder::Level = $Test::Builder::Level + 1;
    #~ my $doc = shift;

    #~ return _generic_count($doc, 'getChildrenByLocalName', [@_]);
#~ }

#~ sub _count_children_by_name
#~ {
    #~ local $Test::Builder::Level = $Test::Builder::Level + 1;
    #~ my $doc = shift;

    #~ return _generic_count($doc, 'getChildrenByTagName', [@_]);
#~ }

#~ sub _count_elements_by_name_ns
#~ {
    #~ local $Test::Builder::Level = $Test::Builder::Level + 1;
    #~ my ($doc, $ns_and_name, $want_count, $blurb) = @_;

    #~ return _multi_arg_generic_count($doc, 'getElementsByTagNameNS',
        #~ [$ns_and_name, $want_count, $blurb]
    #~ );
#~ }

#~ sub _count_children_by_name_ns
#~ {
    #~ local $Test::Builder::Level = $Test::Builder::Level + 1;
    #~ my ($doc, $ns_and_name, $want_count, $blurb) = @_;

    #~ return _multi_arg_generic_count($doc, 'getChildrenByTagNameNS',
        #~ [$ns_and_name, $want_count, $blurb]
    #~ );
#~ }
