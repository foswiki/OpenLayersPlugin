   
# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2011 Taxonomy Research & Information Network (TRIN), http://taxonomy.org.au/
# Author - Paul James Alexander
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html
package Foswiki::Plugins::OpenLayersPlugin;

# Always use strict to enforce variable scoping
use strict;
use warnings;

use Foswiki::Func    ();    # The plugins API
use Foswiki::Plugins ();    # For the API version
use Data::Dumper;

# $VERSION is referred to by Foswiki, and is the only global variable that
# *must* exist in this package. This should always be in the format
# $Rev$ so that Foswiki can determine the checked-in status of the
# extension.
our $VERSION = '$Rev$';

our $RELEASE = '1.1.1';

# Short description of this plugin
# One line description, is shown in the %SYSTEMWEB%.TextFormattingRules topic:
our $SHORTDESCRIPTION = 'OpenLayers Javascript library for Foswiki';


our $NO_PREFS_IN_TOPIC = 1;



my $pubUrlPath ;
# my $hostUrl;
my $isGoogleLayer;
my $mapProjection;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }


   # check for prerequisites
   unless (defined(&Foswiki::Func::addToZone)) {
      Foswiki::Func::writeWarning(
          "ZonePlugin not installed/enabled...disabling OpenLayersPlugin");
      return 0;
  }
    require Foswiki::Plugins::JQueryPlugin;

    $pubUrlPath = Foswiki::Func::getPubUrlPath();
#     $hostUrL    = Foswiki::Func::getUrlHost();
    # Example code of how to get a preference value, register a macro
    # handler and register a RESTHandler (remove code you do not need)

    # Set your per-installation plugin configuration in LocalSite.cfg,
    # like this:
    # $Foswiki::cfg{Plugins}{EmptyPlugin}{ExampleSetting} = 1;
    # See %SYSTEMWEB%.DevelopingPlugins#ConfigSpec for information
    # on integrating your plugin configuration with =configure=.

    # Always provide a default in case the setting is not defined in
    # LocalSite.cfg.
    # my $setting = $Foswiki::cfg{Plugins}{EmptyPlugin}{ExampleSetting} || 0;

    # Register the _EXAMPLETAG function to handle %EXAMPLETAG{...}%
    # This will be called whenever %EXAMPLETAG% or %EXAMPLETAG{...}% is
    # seen in the topic text.
    Foswiki::Func::registerTagHandler( 'OPENLAYERSMAP', \&_OPENLAYERSMAP );

    # Allow a sub to be called from the REST interface
    # using the provided alias
#     Foswiki::Func::registerRESTHandler( 'openlayersmap', \&restExample );

    # Plugin correctly initialized
    return 1;
}

sub typehandler_worldwind {
    my ($layerObject, $layerFormObject) = @_;
    my ($layerweb, $layertopic) = ($layerObject->web(), $layerObject->topic());
    my @fields = $layerObject->find('FIELD');
    my %data;
    my @returnString;    
    
    foreach my $field (@fields) {
        $data{$field->{name}} = $field->{value};
    }
    if ($data{URL} and $data{URL} =~ /\w/) {
        if (not $data{URL} =~ /^(\/|$Foswiki::cfg{LinkProtocolPattern})/) {
            my ($dataweb, $datatopic) = Foswiki::Func::normalizeWebTopicName($layerweb, $data{URL});
            $data{URL} = Foswiki::Func::getScriptUrl($dataweb, $datatopic, qw(view skin text section json));
        }
    } else {
        return "<span class='foswikiAlert'>[[$layerweb.$layertopic]] does not contain a URL</span>";
    }
        
    push @returnString, <<"HERE";
        var wwlayer$layertopic = new OpenLayers.Layer.WorldWind( "$data{Name}",
            "$data{URL}", $data{TileSize}, $data{ZoomLevels},
            {$data{ServerParams}}, {$data{ClientOptions}});
        map.addLayers([wwlayer$layertopic]);
HERE

    my $returnString = "\n".join("\n", @returnString)."\n";
    
    return $returnString;

}

sub typehandler_google {
    my ($layerObject, $layerFormObject) = @_;
    my ($layerweb, $layertopic) = ($layerObject->web(), $layerObject->topic());
    my @fields = $layerObject->find('FIELD');
    my %data;
    my @returnString;    
    $isGoogleLayer = 'true';
    
    foreach my $field (@fields) {
        $data{$field->{name}} = $field->{value};
    }
        
    push @returnString, <<"HERE";
        var googlelayer$layertopic = new OpenLayers.Layer.Google.v3(
            "$data{Name}",
            {type: $data{Type}, numZoomLevels: 22}
        );
        map.addLayers([googlelayer$layertopic]);
HERE

    my $returnString = "\n".join("\n", @returnString)."\n";
    
    return $returnString;

}

sub typehandler_wms {
    my ($layerObject, $layerFormObject) = @_;
    my ($layerweb, $layertopic) = ($layerObject->web(), $layerObject->topic());
    my @fields = $layerObject->find('FIELD');
    my %data;
    my @returnString;     
    
    foreach my $field (@fields) {
        $data{$field->{name}} = $field->{value};
    }
    if ($data{URL} and $data{URL} =~ /\w/) {
        if (not $data{URL} =~ /^(\/|$Foswiki::cfg{LinkProtocolPattern})/) {
            my ($dataweb, $datatopic) = Foswiki::Func::normalizeWebTopicName($layerweb, $data{URL});
            $data{URL} = Foswiki::Func::getScriptUrl($dataweb, $datatopic, qw(view skin text section json));
        }
    } else {
        return "<span class='foswikiAlert'>[[$layerweb.$layertopic]] does not contain a URL</span>";
    }
        
    push @returnString, <<"HERE";
        var wmslayer$layertopic = new OpenLayers.Layer.WMS(
            '$data{Name}',
            '$data{URL}',
            {$data{ServerParams}}, {$data{ClientOptions}});
        map.addLayers([wmslayer$layertopic]);
HERE

    my $returnString = "\n".join("\n", @returnString)."\n";
    
    return $returnString;

}
sub typehandler_kml {
    my ($layerObject, $layerFormObject) = @_;
    my ($layerweb, $layertopic) = ($layerObject->web(), $layerObject->topic());
    my @fields = $layerObject->find('FIELD');
    my %data;
    my @returnString;
    my $strategy;
    my $style;
    
    foreach my $field (@fields) {
        $data{$field->{name}} = $field->{value};
    }
    
    #my $extractStyles = $data{ExtractStyles};
    my $extractStyles = Foswiki::Func::isTrue($data{ExtractStyles}, 0) ? 'true' : 'false';
    #'off' unless defined $extractStyles;
    #$extractStyles = ($extractStyles eq 'on')?'true':'false';
    
    #my $extractAttributes = $data{ExtractAttributes};
    #$extractAttributes = 'on' unless defined $extractAttributes;
    #$extractAttributes = ($extractAttributes eq 'on')?'true':'false';
    my $extractAttributes = Foswiki::Func::isTrue($data{ExtractAttributes}, 0) ? 'true' : 'false';
    
    #my $isBaseLayer = $data{IsBaseLayer};
    #$isBaseLayer = 'false' unless defined $isBaseLayer;
    #$isBaseLayer = ($isBaseLayer eq 'true')?'true':'false';
    my $isBaseLayer = Foswiki::Func::isTrue($data{IsBaseLayer}, 0) ? 'true' : 'false';
    
    my $clustering = $data{Clustering};
#     my $distance;
#     my $threshold;
    $clustering = 'on' unless defined $clustering;
#     $clustering = ($clustering eq 'on')?'true':'false';
    
    if ($clustering && $clustering =~ /^(\d+),\s*(\d+)$/) {
        my $distance = $1;
        my $threshold = $2;
        $strategy = ", new OpenLayers.Strategy.Cluster({distance: $distance, threshold: $threshold})";
        $clustering = 'true';
    } elsif (Foswiki::Func::isTrue($clustering, 1)) {
        $clustering = 'true';
        $strategy = ", new OpenLayers.Strategy.Cluster()";
    } else {
        $clustering = 'false';
    }
    
    if ($clustering eq 'true') {
         $style=<<"HERE";
        //Create a style map object and set the 'default' intent to the
    var vector_style_map$layertopic = new OpenLayers.StyleMap({
        'default': style
    });
//Add the style map to the vector layer threshold, distance
    kmllayer$layertopic.styleMap = vector_style_map$layertopic;
HERE
    }
    
    if ($data{URL} and $data{URL} =~ /\w/) {
        if (not $data{URL} =~ /^(\/|$Foswiki::cfg{LinkProtocolPattern})/) {
            my ($dataweb, $datatopic) = Foswiki::Func::normalizeWebTopicName($layerweb, $data{URL});
            $data{URL} = Foswiki::Func::getScriptUrl($dataweb, $datatopic, qw(view skin text section json));
        }
    } else {
        return "<span class='foswikiAlert'>[[$layerweb.$layertopic]] does not contain a URL</span>";
    }
        
    push @returnString, <<"HERE";
        var kmllayer$layertopic = new OpenLayers.Layer.Vector(
            "$data{Name}",
            { strategies: [new OpenLayers.Strategy.Fixed() $strategy],
                protocol: new OpenLayers.Protocol.HTTP({
                    url: "$data{URL}",
                    format: new OpenLayers.Format.KML({
                        extractStyles: $extractStyles,
                        extractAttributes: $extractAttributes
                    })
                })
            }); 
  
    map.addLayers([kmllayer$layertopic]);
    
        select = new OpenLayers.Control.SelectFeature(kmllayer$layertopic);
    kmllayer$layertopic.events.on({
        "featureselected": onFeatureSelect,
        "featureunselected": onFeatureUnselect
    });

map.addControl(select);
select.activate();

    $style
HERE

    my $returnString = "\n".join("\n", @returnString)."\n";
    
    return $returnString;

}

sub typehandler_vector {
    my ($layerObject, $layerFormObject) = @_;
    my ($layerweb, $layertopic) = ($layerObject->web(), $layerObject->topic());
    my @fields = $layerObject->find('FIELD');
    my %data;
    my $strategy;
    my $style;
    my @returnString;  
    my $proxy = '../Applications/OpenLayers'.'.Proxy?skin=text;'.'url=';
    
    my $isBaseLayer = $data{IsBaseLayer};
    $isBaseLayer = 'false' unless defined $isBaseLayer;
    $isBaseLayer = ($isBaseLayer eq 'true')?'true':'false';
    
    foreach my $field (@fields) {
        $data{$field->{name}} = $field->{value};
    }
    
    my $clustering = $data{Clustering};
    $clustering = 'on' unless defined $clustering;
    $clustering = ($clustering eq 'on')?'true':'false';

    if ($clustering eq 'true') {
        $strategy = ", new OpenLayers.Strategy.Cluster()";
        $style=<<"HERE";
        //Clustering = $clustering Create a style map object and set the 'default' intent to the
var wikilayer_style_map$layertopic = new OpenLayers.StyleMap({
'default': style
});
//Add the style map to the vector layer
wikilayer$layertopic.styleMap = wikilayer_style_map$layertopic;
HERE
    }
    
    if ($data{URL} and $data{URL} =~ /\w/) {
        if (not $data{URL} =~ /^(\/|$Foswiki::cfg{LinkProtocolPattern})/) {
            my ($dataweb, $datatopic) = Foswiki::Func::normalizeWebTopicName($layerweb, $data{URL});
            $data{URL} = Foswiki::Func::getScriptUrl($dataweb, $datatopic, qw(view skin text section json));
        }
    } else {
        return "<span class='foswikiAlert'>[[$layerweb.$layertopic]] does not contain a URL</span>";
    }
        
    push @returnString, <<"HERE";
    //OpenLayers.ProxyHost = '$proxy';
        var wikilayer$layertopic = new OpenLayers.Layer.Vector('$data{Name}',{
            protocol: new OpenLayers.Protocol.HTTP({
                url: '$data{URL}',
                format: new OpenLayers.Format.GeoJSON({})                    
            }),
            strategies: [new OpenLayers.Strategy.Fixed()$strategy]
        });

        map.addLayers([wikilayer$layertopic]);
        $style
HERE

    my $returnString = "\n".join("\n", @returnString)."\n";
    
    return $returnString;

}

# The function used to handle the %EXAMPLETAG{...}% macro
# You would have one of these for each macro you want to process.
sub _OPENLAYERSMAP {
    my($session, $params, $topic, $web, $topicObject) = @_;
    # $session  - a reference to the Foswiki session object
    #             (you probably won't need it, but documented in Foswiki.pm)
    # $params=  - a reference to a Foswiki::Attrs object containing 
    #             parameters.
    #             This can be used as a simple hash that maps parameter names
    #             to values, with _DEFAULT being the name for the default
    #             (unnamed) parameter.
    # $topic    - name of the topic in the query
    # $web      - name of the web in the query
    # $topicObject - a reference to a Foswiki::Meta object containing the
    #             topic the macro is being rendered in (new for foswiki 1.1.x)
    # Return: the result of processing the macro. This will replace the
    # macro call in the final text.

    # For example, %EXAMPLETAG{'hamburger' sideorder="onions"}%
    # $params->{_DEFAULT} will be 'hamburger'
    # $params->{sideorder} will be 'onions'
    
     Foswiki::Func::addToZone(
        "script",
        "OPENLAYERSPLUGIN::OPENLAYERMAP::OPENLAYERS", 
        "<script src='$pubUrlPath/$Foswiki::cfg{SystemWebName}/OpenLayersPlugin/scripts/api/2/OpenLayers.js'></script>",
        "OPENLAYERSPLUGIN"
   );
#          Foswiki::Func::addToZone(
#         "script",
#         "OPENLAYERSPLUGIN::OPENLAYERMAP::OPENLAYERS", 
#         "<script src='$pubUrlPath/$Foswiki::cfg{SystemWebName}/OpenLayersPlugin/scripts/api/3/OpenLayers.js'></script>",
#         "OPENLAYERSPLUGIN"
#    );

    Foswiki::Func::addToZone(
        "script",
        "OPENLAYERSPLUGIN",
        "<script type='text/javascript'>jQuery(document).ready(function () { init(); });</script>"
    );

    my @mapMetadata;
    my @scriptVariable;
    my $viewPortLayer;

    my $mapHeight = $params->{mapheight};
    $mapHeight = '600' unless defined $mapHeight;
    $mapHeight = $mapHeight.'px';
#     push @mapMetadata, "mapHeight:$mapHeight";

    my $mapWidth = $params->{mapwidth};
    $mapWidth = 'my800' unless defined $mapWidth;  #FullWidth
    $mapWidth = $mapWidth.'px';
#     push @mapMetadata, "mapHeight:$mapWidth";

    my $mapViewPort = $params->{viewport};
    $mapViewPort = '149.128847,-35.28052' unless defined $mapViewPort;
#     push @mapMetadata, "mapViewPort:$mapViewPort";
    if ($mapViewPort =~ /$params->{layertopics}/) {
        $viewPortLayer = 'true';
    }

    my $mapViewPortZoom = $params->{viewportzoom};
    $mapViewPortZoom = '1' unless defined $mapViewPortZoom;
#     push @mapMetadata, "mapViewPortZoom:$mapViewPortZoom";
 
    my @layerScripts;

    my @layers = split(/,\s*/, ($params->{layertopics} || ''));
    my $mapsWeb = Foswiki::Func::getPreferencesValue('OPENLAYERSPLUGIN_MAPSWEB') || 'Applications/OpenLayers/Layers';
    my $mapsTopic = Foswiki::Func::getPreferencesValue('OPENLAYERSPLUGIN_DEFAULTMAP') || 'Applications/OpenLayers/Layers/DefaultMap';



# Default Base MAP
#     push @layerScripts, <<"HERE";
#         // Rendering Base Map
#    var mapOptions = { maxResolution: 45/512, numZoomLevels: 11, fractionalZoom: true};
#    map = new OpenLayers.Map(mapOptions);
# 
#     var wwlayerdemis = new OpenLayers.Layer.WorldWind( "World",
#         "http://www2.demis.nl/wms/ww.ashx?", 45, 11,
#         {T:'WorldMap'}, {tileSize: new OpenLayers.Size(512,512), wrapDateLine:true});
#     map.addLayers([wwlayerdemis]);
# 
#     var viewportcorner = new OpenLayers.LonLat($mapViewPort);
#     if (map.isValidLonLat(viewportcorner) && $mapViewPortZoom) {
#         map.moveTo(viewportcorner,$mapViewPortZoom);
#     }
# HERE

    if (not scalar(@layers)) {
        
#         return '<span class="foswikiAlert">No layer topics specified!</span>';
#       Assign a Default Map
#         push @layers, $mapsTopic; 
    }
    
    foreach my $layername (@layers) {
        my ($layerweb, $layertopic) = Foswiki::Func::normalizeWebTopicName($mapsWeb, $layername);
        my ($topicObject) = Foswiki::Func::readTopic($layerweb, $layertopic);
        my $formObject;
        my ($formweb, $formtopic);
        my $form = $topicObject->get('FORM');
        my @fields = $topicObject->find('FIELD');
        my $layertype; # vector, wms, google etc.
        
        if (ref($form) eq 'HASH' and $form->{name}) {
            ($formweb, $formtopic) = Foswiki::Func::normalizeWebTopicName($layerweb, $form->{name});
            
            ($formObject) = Foswiki::Func::readTopic($formweb, $formtopic);
            $layertype = $formObject->get('FIELD', 'LayerType');
            if (ref($layertype) eq 'HASH' and $layertype->{value}) {
                $layertype = $layertype->{value};
            } else {
                return "<span class='foswikiAlert'>[[$layerweb.$layertopic]] form [[$formweb.$formtopic]] didn't have a LayerType field</span";
            }
        } else {
            return "<span class='foswikiAlert'>[[$layerweb.$layertopic]] didn't have a form attached</span>";
        }
        if (scalar(@fields)) {
            my %data; #= map { $_->{name} => $_->{value} } @{$fields};
            my $typehandler = 'Foswiki::Plugins::OpenLayersPlugin::typehandler_' . $layertype;
             
            if (defined &{$typehandler}) {
                my $result;
                {
                    no strict 'refs';
                    $result = &{$typehandler}($topicObject, $formObject);
                    use strict 'refs';
                }
                push @layerScripts, $result;
            } else {
                return "<span class='foswikiAlert'>[[$layerweb.$layertopic]] form [[$formweb.$formtopic]]: no handler for '$layertype' type</span>";
            }            
        } else {
            return "<span class='foswikiAlert'>[[$layerweb.$layertopic]] doesn't contain any formfield values</span>"
        }
    
    }

#     push @scriptVariable, <<"HERE";
#     // Rendering Default Base Map
#    //var mapOptions = {allOverlays: true};
#      var mapOptions = { maxResolution: 45/512, numZoomLevels: 11, fractionalZoom: true};
#    //map = new OpenLayers.Map(mapOptions);
#     
#        
#    //mapOptions = {
#      //               projection: "EPSG:900913",
#        //             units: "m",
#          //           maxExtent: new OpenLayers.Bounds( -20037508, -20037508, 20037508, 20037508)
#      //       };
# 
#         var map = new OpenLayers.Map(mapOptions);
# HERE

    push @scriptVariable, <<"HERE";
        var mapOptions = { maxResolution: 45/512, numZoomLevels: 11, fractionalZoom: true};
        map = new OpenLayers.Map(mapOptions);
HERE

    my $mapLayerSwitcher = $params->{layerswitcher};
    $mapLayerSwitcher = 'off' unless defined $mapLayerSwitcher;
    $mapLayerSwitcher = ($mapLayerSwitcher eq 'on')?'true':'false';
    if ($mapLayerSwitcher) {
        push @scriptVariable, 'map.addControl(new OpenLayers.Control.LayerSwitcher({}));';
    }
    
    my $mapMaxResolution = $params->{mapmaxresolution} || '45/512';    
    my $mapMinResolution = $params->{mapminresulution} || 'auto';
    my $mapNumZoomlLevels = $params->{mapnumzoomlevels} || '16';
    my $mapMaxScale = $params->{mapmaxscale} || '23';
    my $mapMinScale = $params->{mapminscale} || '23';
    my $mapProjection = $params->{mapprojection} || 'EPSG:4326';
    my $mapUnits = $params->{mapunits} || 'degrees';
#    my $mapFractionalZoom = $params->{fractionalzoom} || 'on';
# 
#     my $baseLayerName = $params->{name} || 'Base Layer';
#     my $baseLayerMinZoomLevel = $params->{baselayerminzoomlevel} || '23';
#     my $baseLayerMaxZoomLevel = $params->{baselayermaxzoomlevel} || '23';
#     my $baseLayerURL = $params->{url} || 'http://vmap0.tiles.osgeo.org/wms/vmap0';
#     my $baseLayerParams = $params->{params} || 'layers: \'basic\'';
#     my $baseLayerOptions = $params->{options} || '23';
#     my $extraProjections = $params->{extraprojections} || 'don\'t include Proj4js if only basic functions required';
# 
#     my $vectorLayerName = $params->{vectorlayername} || 'Vector Layer';
#     my $vectorLayerCluster = $params->{vectorLayerCluster} || 'on' ;
#     my $mapVectorLayerEditingToolbar = $params->{mapvectorlayereditingtoolbar} || 'off';
# 
#     my $vectorLayerFeatures = $params->{vectorlayerfeatures} || 'filename or GEOJSON';

#     my $kmlLayer = $params->{kmllayerfilename} || 'filename';
#     
#     my $osmLayerName = $params->{osmlayername}|| 'OSM Layer';
#     my $osmLayerAttribution = $params->{osmlayerattribution} || '23';
# 
#     my $wmsLayerName = $params->{wmslayername} || 'WMS Layer';
#     my $wmsLayerURL = $params->{wmslayerurl} || 'http://vmap0.tiles.osgeo.org/wms/vmap0';
#     my $wmsLayerParams = $params->{wmslayerparams}|| 'default';
#     my $wmsIsBaseLayer = $params->{wmsisbaselayer} || 'isBaseLayer:true';
#     my $wmsLayerOpacity = $params->{wmslayeropacity} || 'opacity: .5';


    my $mapFractionalZoom = $params->{fractionalzoom};
    $mapFractionalZoom = 'on' unless defined $mapFractionalZoom;
    $mapFractionalZoom = ($mapFractionalZoom eq 'on')?'true':'false';
    push @mapMetadata, "mapFractionalZoom:$mapFractionalZoom";

   
    my @layerList = ();
    my @jsFragments;
#     my @createMap;
#     my $isGoogleLayer;
    my $mapLayers = $params->{layers};

    my $mapDiv='';
    my $mapElement = $params->{mapelement};
    if (!defined $mapElement) {
        $mapElement = 'openlayersmap';
        $mapDiv = "<div id='$mapElement' style='height:$mapHeight; width:$mapWidth; position:relative;'></div>";
    }
    
     push @scriptVariable, <<"HERE";
      var style = new OpenLayers.Style({
      pointRadius: "\${radius}",
      fillColor: "#ffcc66",
      fillOpacity: 0.8,
      strokeColor: "#cc6633",
      label: "\${pointLabel}",
      strokeWidth: "\${width}",
      strokeOpacity: 0.8
   }, {
      context: {
         width: function(feature) {
            return (feature.cluster) ? 2 : 1;
         },
         pointLabel: function(feature) {
            return (feature.cluster) ? feature.attributes.count : "feature.attributes.name" ;
         },
         radius: function(feature) {
            var pix = 3;
            if(feature.cluster) {
               pix = Math.min(feature.attributes.count, 7) + 3;
            }
            return pix;
         }
      }
   });
HERE

    push @scriptVariable, @layerScripts;

#     push @scriptVariable, <<"HERE";
#     var style = new OpenLayers.Style({
#         pointRadius: "\${radius}",
#         fillColor: "#ffcc66",
#         fillOpacity: 0.8,
#         strokeColor: "#cc6633",
#         label: "\${pointLabel}",
#         strokeWidth: "\${width}",
#         strokeOpacity: 0.8
#     }, {
#         context: {
#             width: function(feature) {
#                 return (feature.cluster) ? 2 : 1;
#             },
#             pointLabel: function(feature) {
#                 return (feature.cluster) ? feature.attributes.count : feature.attributes.pointLabel ;
#             },
#             radius: function(feature) {
#                 var pix = 3;
#                 if(feature.cluster) {
#                     pix = Math.min(feature.attributes.count, 7) + 3;
#                 }
#                 return pix;
#             }
#         }
#     });
# HERE
# 
        push @scriptVariable, <<"HERE";
    var strategy = new OpenLayers.Strategy.Cluster();
    strategy.distance= 20;
    strategy.threshold=2;
    var styleselect = new OpenLayers.Style({fillColor: "#8aeeef",strokeColor: "#32a8a9"});

    var styleMap= new OpenLayers.StyleMap({
        "default": style,
        "select": styleselect }); 
HERE

#         push @scriptVariable, <<"HERE";
#     if(!map.getCenter()){
#         map.zoomToMaxExtent();
#     }
#     map.render('$mapElement');
# HERE

    if ($viewPortLayer eq 'true') {
        # Set View port to bounds of $mapViewPort
    }


        push @scriptVariable, <<"HERE";

    var proj = new OpenLayers.Projection("EPSG:4326");
    if (map.isValidLonLat($mapViewPort) && $mapViewPortZoom) {
        var point = new OpenLayers.LonLat($mapViewPort);
        point.transform(proj, map.getProjectionObject());
        map.setCenter(point, $mapViewPortZoom);
        //map.moveTo($mapViewPort,$mapViewPortZoom);
    }
    
    map.render('$mapElement');

HERE

    if ($isGoogleLayer eq 'true') {
        Foswiki::Func::addToZone(
            "script",
            "OPENLAYERSPLUGIN", 
            "<script src='http://maps.google.com/maps/api/js?v=3.2&sensor=false'></script>"
        );
    }
    
    my $mapFunctions = <<"HERE";
    <script type="text/javascript">
    
            function onPopupClose(evt) {
            select.unselectAll();
        }

        function onFeatureSelect(event) {
            var feature = event.feature;
            // Since KML is user-generated, do naive protection against
            // Javascript.
            var content = "<h2>"+feature.attributes.name + "</h2>" + feature.attributes.description;
            if (content.search("<script") != -1) {
                content = "Content contained Javascript! Escaped content below.<br>" + content.replace(/</g, "&lt;");
            }
            popup = new OpenLayers.Popup.FramedCloud("chicken",
                feature.geometry.getBounds().getCenterLonLat(),
                new OpenLayers.Size(100,100),
                content,
                null, true, onPopupClose);
            feature.popup = popup;
            map.addPopup(popup);
        }
    function onFeatureUnselect(event) {
        var feature = event.feature;
            if(feature.popup) {
                map.removePopup(feature.popup);
                feature.popup.destroy();
                delete feature.popup;
            }
        }
    </script>
        
HERE

        Foswiki::Func::addToZone(
        "script",
        "OPENLAYERSPLUGIN::OPENLAYERSMAP",
        "$mapFunctions",
        "OPENLAYERSPLUGIN"
    );


    my $scriptVariable = "<script type='text/javascript'> var map, select; function init()  {  \n".join("\n", @scriptVariable)."}\n</script>";

    Foswiki::Func::addToZone(
        "script",
        "OPENLAYERSPLUGIN::OPENLAYERSMAP::$mapElement",
        "$scriptVariable",
        "OPENLAYERSPLUGIN"
    );

#    my $mapMetadata = "<script type='text/javascript'>var metadata = {".join(",\n", @mapMetadata)."}</script>";
#     Foswiki::Func::addToZone(
#         "script",
#         "OPENLAYERSPLUGIN::OPENLAYERSMAP::META$mapElement",
#         "$mapMetadata",
#         "OPENLAYERSPLUGIN"
#     );


    return $mapDiv;
}


1;

__END__
Foswiki - The Free and Open Source Wiki, http://foswiki.org/

Copyright (C) 2008-2011 Foswiki Contributors. Foswiki Contributors
are listed in the AUTHORS file in the root of this distribution.
NOTE: Please extend that file, not this notice.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.e For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
