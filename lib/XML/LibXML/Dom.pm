use v6.c;

use XML::LibXML::CStructs :types;


package XML::LibXML::Dom {

    use NativeCall;

    use XML::LibXML::Enums;
    use XML::LibXML::Subs;

    sub _domAddNsChain(xmlNsPtr $c, xmlNsPtr $ns) {
        return $ns unless $c =:= xmlNsPtr;

        my $i = $c;
        while $i !=:= xmlNsPtr && $i !=:= $ns {
            $i = nativecast(xmlNs, $i).next;
            if $i =:= xmlNsPtr {
                nativecast(xmlNs, $ns).next = $c;
                return $ns;
            }
        }

        return $c;
    }

    sub _domReconcileNsAttr(xmlAttrPtr $a, xmlNsPtr $unused) {
        return unless $a.defined;

        my $attr = nativecast(xmlAttr, $a);

        my xmlNodePtr $tree = $attr.parent;
        my xmlNode $tree_o = nativecast(xmlNode, $tree);

        return unless $tree.defined;

        if $attr.ns.defined {
            my xmlNsPtr $ns;

            if $attr.ns.name.defined && $attr.ns.name eq 'xml' {
                $ns = xmlSearchNsByHref($tree.doc, $tree, XML_XML_NAMESPACE);
                $attr.setNs($ns);
                return
            } 
            else {
                $ns = xmlSearchNs($tree_o.doc, $tree_o.parent, $attr.ns.name);
            }

            my $nso = nativecast(xmlNs, $ns);
            if [&&](
                $ns.defined,
                $nso.uri.defined,
                $attr.ns.uri.defined,
                $nso.uri eq $attr.ns.uri
            ) {
                if domRemoveNsDef($tree, $attr.ns) {
                    $unused = _domAddNsChain($unused, $attr.ns);
                    $attr.setNs($ns);
                }
            } 
            else {
                if domRemoveNsDef($tree, $attr.ns) {
                    domAddNsDef($tree, $attr.ns);
                } 
                else {
                    $attr.setNs(xmlCopyNamespace($attr.ns));
                    domAddNsDef($tree, $attr.ns) if $attr.ns.defined;
                }
            }
        }
    }

    #sub _domReconcileNs(xmlNode $tree, xmlNs $unused) {
    sub _domReconcileNs($tree, $unused) {
        sub xmlCopyNamespace(xmlNs) returns xmlNs is native('xml2') { * }

        if  $tree.ns !~~ Nil     
         	&& ($tree.type == XML_ELEMENT_NODE || 
         		$tree.type == XML_ATTRIBUTE_NODE) {
            my $ns = xmlSearchNs($tree.doc, $tree.parent, $tree.ns.uri);
            if [&&](
                $ns.defined,
                $ns.href.defined,
                $tree.ns.href.defined,
                $ns.href eq $tree.ns.href
            ) {
                $unused = _domAddNsChain($unused, $tree.ns)
                    if domRemoveNsDef($tree, $tree.ns);
                $tree.ns = $ns;
            } 
            else {
        # cw: Endless loop here...            
	            if domRemoveNsDef($tree, $tree.ns) {
	    #           domAddNsDef($tree, $tree.ns);
	    #       } else {
	    #           $tree.ns = xmlCopyNamespace($tree.ns);
	    #           domAddNsDef($tree, $tree.ns);
	            }
            }
        }

        if $tree.type == XML_ELEMENT_NODE {
            my xmlElement $ele = nativecast(xmlElement, $tree);

            my xmlAttrPtr $a_p = $ele.attributes;
            while $a_p.defined {
                _domReconcileNsAttr($a_p, $unused);
                $a_p = nativecast(xmlAttr, $a_p).next;
            }
        }

        my xmlNodePtr $c_p = $tree.children;
        while $c_p.defined {
            _domReconcileNs($c_p, $unused);
            $c_p = nativecast(xmlNode, $c_p).next;
        }
    }

    sub domReconcileNs(xmlNode $tree) is export {
        sub xmlFreeNsList(xmlNsPtr) is native('xml2') { * };

        my xmlNsPtr $unused;
        _domReconcileNs($tree, $unused);
        xmlFreeNsList($unused) if $unused.defined;
    }

    # cw: This implementation is shit. For one thing we really need to move
    #     away from "pointer-think"
    sub domAddNsDef(xmlNode $t, xmlNs $ns) {
        my xmlNs $i = $t.nsDef;

        $i = $i.next while $i.defined && $i !=:= $ns;

        unless $i.defined {
            $ns.next = $t.nsDef;
            $t.setNsDef($ns);
        }
    }

    sub domImportNode(xmlDoc $d, xmlNode $n, $move, $reconcileNS) is export {
        sub xmlCopyDtd(Pointer) returns Pointer is native('xml2') { * }
        sub xmlDocCopyNode(xmlNode, xmlDoc, int32) returns xmlNode is native('xml2') { * }

        my xmlNode $return_node = $n;

        if $move {
            $return_node = $n;
            domUnlinkNode(nativecast(xmlNodePtr, $n));
        } 
        else {
            if ($n.type == XML_DTD_NODE) {
                # cw: Pointer should be xmlDtd, but that hasn't been defined, yet.
                $return_node = nativecast(
                    xmlNode, xmlCopyDtd(nativecast(Pointer, $n));
                );
            } 
            else {
                $return_node = xmlDocCopyNode($n, $d, 1);
            }
        }

        if $n.defined && $n.doc !=:= $d {
            # cw: There is XS memory management code at this point that 
            #     I'm hoping we can ignore:
            #if (PmmIsPSVITainted(node->doc))
            #    PmmInvalidatePSVI(doc);
            xmlSetTreeDoc($return_node, $d);
        }

        if 
            $reconcileNS.defined      && 
            $d.defined                && 
            $return_node.defined      &&
            $return_node.type != XML_ENTITY_REF_NODE
        {
            domReconcileNs($return_node);
        }
    }

    sub domGetAttrNode(xmlNode $n, Str $a) is export {
        my $name = $a.subst(/\s/, '');
        return unless $name;

        my $ret;
        unless $ret := nativecast(
            xmlAttr, xmlHasNsProp($n, $a, Str)
        ) {
            my ($prefix, $localname) = $a.split(':');

            if !$localname {
                $localname = $prefix;
                $prefix = Nil;
            }
            if $localname {
                my $ns = xmlSearchNs($n.doc, $n, $prefix);
                if $ns {
                    $ret := nativecast(
                        xmlAttr, xmlHasNsProp($n, $localname, $ns.uri)
                    );
                }
            }
        }

        return if $ret && $ret.type != XML_ATTRIBUTE_NODE;
        return $ret;
    }

    # cw: Type check sends rakudo into an endless loop!
    #
    #sub domRemoveNsDef(xmlNodePtr $tree, xmlNsPtr $ns) {
    #    
    sub domRemoveNsDef($_tree, $_ns) {
        my $tree = $_tree ~~ xmlNodePtr ??
            nativecast(xmlNode, $_tree) !! $_tree;
        my $ns = $_ns ~~ xmlNsPtr ??
            nativecast(xmlNs, $_ns) !! $_ns;

        my xmlNs $i = $tree.nsDef;

        if ($ns =:= $tree.nsDef) {
            $tree.setNsDef($tree.nsDef.next);
            $ns.next = xmlNs;
            return 1;
        }

        while $i.defined {
            if $i.next =:= $ns {
                $i.next = nativecast(xmlNodePtr, $ns.next);
                $ns.next = xmlNsPtr;
                return 1;
            }
            $i = $i.next;
        }

        return 0;
    }

    sub domUnlinkNode(xmlNodePtr $n) {
        my $node = nativecast(xmlNode, $n);

        return if 
            !$n.defined || !($node.prev.defined || $node.parent.defined);
        
        if $node.type == XML_DTD_NODE {
            xmlUnlinkNode($node);
            return;
        }

        nativecast(xmlNode, $node.prev).next = $node.next 
            if $node.prev.defined;
        nativecast(xmlNode, $node.next).prev = $node.prev 
            if $node.next.defined;

        if ($node.parent.defined) {
            nativecast(xmlNode, $node.parent).last = $node.prev
                if $node =:= $node.parent.last;

            nativecast(xmlNode, $node.parent).children = $node.next
                if $node =:= $node.parent.children;
        }

        $node.prev = xmlNodePtr;
        $node.next = xmlNodePtr;
        $node.parent = xmlNodePtr;
    }

    sub domFixOwner($node_to_fix, $new_parent) {

    }

    sub testNodeName(Str $n) is export {
        return False if ($n ~~ /^<-[ a..z A..Z \_ : ]>/) !~~ Nil;

        # cw: Missing IS_EXTENDER(c)
        return ($n ~~ /<-[ \d a..z A..Z : \- \. ]>/) ~~ Nil;
    }

}