   
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

    my @mapMetadata;

    my $mapHeight = $params->{mapheight};
    $mapHeight = '600' unless defined $mapHeight;
    $mapHeight = $mapHeight.'px';
    push @mapMetadata, "mapHeight:$mapHeight";

    my $mapWidth = $params->{mapwidth};
    $mapWidth = 'my800' unless defined $mapWidth;
    $mapWidth = $mapWidth.'px';
    push @mapMetadata, "mapHeight:$mapWidth";

    my $mapViewPort = $params->{viewport};
    $mapViewPort = '159,-32' unless defined $mapViewPort;
    push @mapMetadata, "mapViewPort:$mapViewPort";

    my $mapViewPortZoom = $params->{viewportzoom};
    $mapViewPortZoom = '1' unless defined $mapViewPortZoom;
    push @mapMetadata, "mapViewPortZoom:$mapViewPortZoom";
 
    my $mapControls = $params->{mapcontrols} || 'ArgParser,Attribution,Navigation,PanZoom';
    my $mapControlsArray = $params->{mapcontrolsarray} || 'navigation_control,new OpenLayers.Control.PanZoomBar({}),new OpenLayers.Control.LayerSwitcher({}),new OpenLayers.Control.Permalink(),new OpenLayers.Control.MousePosition({})' ;
    my $navigationOptions = $params->{navigation} || 'DragPan,ZoomBox,Handler.Click,Handler.Wheel';
    my $wheelNavigation = $params->{wheelnavigation} || 'disableWheelNavigation:false';
    my $mapcontrolGraticule = $params->{graticule} || 'off';
#    my $layerSwitcher = $params->{layerswitcher} || 'on';

    my $mapMaxResolution = $params->{mapmaxresolution} || '45/512';    
    my $mapMinResolution = $params->{mapminresulution} || 'auto';
    my $mapNumZoomlLevels = $params->{mapnumzoomlevels} || '16';
    my $mapMaxScale = $params->{mapmaxscale} || '23';
    my $mapMinScale = $params->{mapminscale} || '23';
    my $mapProjection = $params->{mapprojection} || 'EPSG:4326';
    my $mapUnits = $params->{mapunits} || 'degrees';
#    my $mapFractionalZoom = $params->{fractionalzoom} || 'on';

    my $baseLayerName = $params->{name} || 'Base Layer';
    my $baseLayerMinZoomLevel = $params->{baselayerminzoomlevel} || '23';
    my $baseLayerMaxZoomLevel = $params->{baselayermaxzoomlevel} || '23';
    my $baseLayerURL = $params->{url} || 'http://vmap0.tiles.osgeo.org/wms/vmap0';
    my $baseLayerParams = $params->{params} || 'layers: \'basic\'';
    my $baseLayerOptions = $params->{options} || '23';
    my $extraProjections = $params->{extraprojections} || 'don\'t include Proj4js if only basic functions required';

    my $vectorLayerName = $params->{vectorlayername} || 'Vector Layer';
    my $vectorLayerCluster = $params->{vectorLayerCluster} || 'on' ;
    my $mapVectorLayerEditingToolbar = $params->{mapvectorlayereditingtoolbar} || 'off';

    my $vectorLayerFeatures = $params->{vectorlayerfeatures} || 'filename or GEOJSON';

    my $kmlLayer = $params->{kmllayerfilename} || 'filename';
    
    my $osmLayerName = $params->{osmlayername}|| 'OSM Layer';
    my $osmLayerAttribution = $params->{osmlayerattribution} || '23';

    my $wmsLayerName = $params->{wmslayername} || 'WMS Layer';
    my $wmsLayerURL = $params->{wmslayerurl} || 'http://vmap0.tiles.osgeo.org/wms/vmap0';
    my $wmsLayerParams = $params->{wmslayerparams}|| 'default';
    my $wmsIsBaseLayer = $params->{wmsisbaselayer} || 'isBaseLayer:true';
    my $wmsLayerOpacity = $params->{wmslayeropacity} || 'opacity: .5';


    my $mapFractionalZoom = $params->{fractionalzoom};
    $mapFractionalZoom = 'on' unless defined $mapFractionalZoom;
    $mapFractionalZoom = ($mapFractionalZoom eq 'on')?'true':'false';
    push @mapMetadata, "mapFractionalZoom:$mapFractionalZoom";


    Foswiki::Func::addToZone(
        "script",
        "OPENLAYERSPLUGIN::OPENLAYERMAP::OPENLAYERS", 
        "<script src='$pubUrlPath/$Foswiki::cfg{SystemWebName}/OpenLayersPlugin/scripts/api/2/OpenLayers.js'></script>",
        "OPENLAYERSPLUGIN"
   );

    Foswiki::Func::addToZone(
        "script",
        "OPENLAYERSPLUGIN",
        "<script type='text/javascript'>jQuery(document).ready(function () { init(); });</script>"
    );
   
    my @layerList = ();
    my @jsFragments;
    my @layerScripts;
    my @scriptVariable;
    my @createMap;
    my $isGoogleLayer;
    my $mapLayerSwitcher;
    my $mapLayers = $params->{layers};

    if ($mapLayers) {
        foreach my $layerID (split(/\s*,\s*/, $mapLayers)) {
            push @layerList, $layerID; 
        }
    push @createMap, <<"HERE";
    var mapOptions = { maxResolution: $mapMaxResolution, numZoomLevels: $mapNumZoomlLevels, fractionalZoom: $mapFractionalZoom}; 
    var map = new OpenLayers.Map(mapOptions); 
HERE

    $mapLayerSwitcher = $params->{layerswitcher};
    $mapLayerSwitcher = 'off' unless defined $mapLayerSwitcher;
    $mapLayerSwitcher = ($mapLayerSwitcher eq 'on')?'true':'false';
    push @mapMetadata, "mapLayerSwitcher:$mapLayerSwitcher";
    if ($mapLayerSwitcher) {
        push @createMap, 'map.addControl(new OpenLayers.Control.LayerSwitcher({}));';
    }
   
    foreach my $layerID (@layerList) {
        my @jsFragment;
        my @layerScript;
        # layer ID
        push @jsFragment, "layerID:'$layerID'";

        # layer type
        my $layerType = $params->{$layerID.'_type'};

        # layer server url
        my $layerURL = $params->{$layerID.'_url'};

        # layer name
        my $layerName = $params->{$layerID.'_name'};
        $layerName = $layerID unless defined $layerName;

        # server params
        my $serverParams = $params->{$layerID.'_serverparams'};

        # client options
        my $clientOptions = $params->{$layerID.'_clientoptions'};

        # is base layer
        my $isBaseLayer = $params->{$layerID.'_isbaselayer'};
        $isBaseLayer = 'on' unless defined $isBaseLayer;
        $isBaseLayer = ($isBaseLayer eq 'on')?'true':'false';

        # layer opacity
        my $layerOpacity = $params->{$layerID.'_layeropacity'};
        $layerOpacity = '0.5' unless defined $layerOpacity;

        # tile size
        my $tileSize = $params->{$layerID.'_tilesize'};

        # zoom levels
        my $zoomLevels = $params->{$layerID.'_zoomlevels'};

        if ($layerType eq 'WMS') {
            push @layerScript, <<"HERE";
        var wmslayer$layerID = new OpenLayers.Layer.WMS( "$layerName",
            "$layerURL",
            {$serverParams}, {$clientOptions});
        wmslayer$layerID.setIsBaseLayer($isBaseLayer);
        map.addLayers([wmslayer$layerID]);
HERE
            if ($isBaseLayer eq 'false') {
                push @layerScript, "\t\twmslayer$layerID.setOpacity($layerOpacity);\n";
            }
        } elsif ($layerType eq 'WW') {
            push @layerScript, <<"HERE";
var wwlayer$layerID = new OpenLayers.Layer.WorldWind( "$layerName",
    "$layerURL", $tileSize, $zoomLevels,
    {$serverParams}, {$clientOptions});
map.addLayers([wwlayer$layerID]);
HERE
        } elsif ($layerType eq 'GOOGLE') {
            $isGoogleLayer = 'true';
            push @layerScript, <<"HERE";
        var googlelayer$layerID = new OpenLayers.Layer.Google(
            'Google Layer',
            {}
        );
        map.addLayers([googlelayer$layerID]);
HERE
        } elsif ($layerType eq 'KML') {
            push @layerScript, '/* KML Layer */';
        } elsif ($layerType eq 'VECTOR') {
            push @layerScript, <<"HERE";
var vectorlayer$layerID = new OpenLayers.Layer.Vector("$layerName",
    {$clientOptions});
map.addControl(new OpenLayers.Control.EditingToolbar(vectorlayer$layerID));
map.addLayers([vectorlayer$layerID]);
HERE
        }

        # javascript Fragments
        push @jsFragments, '{ '.join(', ', @jsFragment).'}';

        # layer scripts
        push @layerScripts, @layerScript;

    }

    push @layerScripts, <<"HERE"
    var viewportcorner = new OpenLayers.LonLat($mapViewPort);
    if (map.isValidLonLat(viewportcorner) && $mapViewPortZoom) {
        map.moveTo(viewportcorner,$mapViewPortZoom);
    }
HERE

    } else { # No layers present use default DEMIS World map
        push @layerScripts, <<"HERE";
   var mapOptions = { maxResolution: 45/512, numZoomLevels: 11, fractionalZoom: true};
   map = new OpenLayers.Map(mapOptions);

    var wwlayerdemis = new OpenLayers.Layer.WorldWind( "World",
        "http://www2.demis.nl/wms/ww.ashx?", 45, 11,
        {T:'WorldMap'}, {tileSize: new OpenLayers.Size(512,512), wrapDateLine:true});
    map.addLayers([wwlayerdemis]);

    var viewportcorner = new OpenLayers.LonLat($mapViewPort);
    if (map.isValidLonLat(viewportcorner) && $mapViewPortZoom) {
        map.moveTo(viewportcorner,$mapViewPortZoom);
    }

HERE
    }

    push @mapMetadata, 'jsFragments: ['.join(",\n", @jsFragments).']';

    push @scriptVariable, @createMap;

    push @scriptVariable, @layerScripts;
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
                return (feature.cluster) ? feature.attributes.count : feature.attributes.pointLabel ;
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

        push @scriptVariable, <<"HERE";
    var strategy = new OpenLayers.Strategy.Cluster();
    strategy.distance= 20;
    strategy.threshold=2;
    var styleselect = new OpenLayers.Style({fillColor: "#8aeeef",strokeColor: "#32a8a9"});

    var styleMap= new OpenLayers.StyleMap({
        "default": style,
        "select": styleselect }); 
HERE

        push @scriptVariable, <<"HERE";
    if(!map.getCenter()){
        map.zoomToMaxExtent();
    }
    map.render('$mapElement');
HERE

    if ($isGoogleLayer eq 'true') {
        Foswiki::Func::addToZone(
            "script",
            "OPENLAYERSPLUGIN", 
            "<script src='http://maps.google.com/maps/api/js?sensor=false'></script>"
        );
    }


    my $scriptVariable = "<script type='text/javascript'>function init()  {  \n".join("\n", @scriptVariable)."}\n</script>";
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


    return "$mapDiv";
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
