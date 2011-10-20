   
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

our $RELEASE = '0.1.1';

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

    my $mapElement = $params->{mapelement} || 'openlayersmap';

    my $mapHeight = $params->{mapheight} || '600';
    my $mapWidth = $params->{mapwidth} || '800';
 
    my $mapControls = $params->{mapcontrols} || 'ArgParser,Attribution,Navigation,PanZoom';
    my $mapControlsArray = $params->{mapcontrolsarray} || 'navigation_control,new OpenLayers.Control.PanZoomBar({}),new OpenLayers.Control.LayerSwitcher({}),new OpenLayers.Control.Permalink(),new OpenLayers.Control.MousePosition({})' ;
    my $navigationOptions = $params->{navigation} || 'DragPan,ZoomBox,Handler.Click,Handler.Wheel';
    my $wheelNavigation = $params->{wheelnavigation} || 'disableWheelNavigation:false';
    my $mapcontrolGraticule = $params->{graticule} || 'off';
    my $layerSwitcher = $params->{layerswitcher} || 'on';

    my $mapMaxResolution = $params->{mapmaxresolution} || 'auto';    
    my $mapMinResolution = $params->{mapminzoomlevel} || 'auto';
    my $mapNumZoomlLevels = $params->{mapnumzoomlevels} || '16';
    my $mapMaxScale = $params->{mapmaxscale} || '23';
    my $mapMinScale = $params->{mapminscale} || '23';
    my $mapProjection = $params->{mapprojection} || 'EPSG:4326';
    my $mapUnits = $params->{mapUnits} || 'degrees';

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


   # sanatize params

    my @mapMetadata = (
        "mapElement: $mapElement",
        "mapHeight: $mapHeight",
        "mapWidth: $mapWidth",
        "mapMaxResolution: $mapMaxResolution",
        "mapMinResolution: $mapMinResolution",
        "mapNumZoomlLevels: $mapNumZoomlLevels",
        "mapMaxScale: $mapMaxScale",
        "mapMinScale: $mapMinScale",
        "mapProjection: $mapProjection",
        "mapUnits: $mapUnits",
    );


    Foswiki::Func::addToZone(
        "script",
        "OpenLayersPlugin", 
       "<script src='$pubUrlPath/$Foswiki::cfg{SystemWebName}/OpenLayersPlugin/scripts/api/2/OpenLayers.js'></script>" 
   );

#     Foswiki::Func::addToZone(
#         "script",
#         "Googkle_API_3.2", 
#        "<script src='http://maps.google.com/maps/api/js?sensor=false&v=3.2'></script>" 
#    );

    
    my @layerList = ();
    my $mapLayers = $params->{layers};
    if ($mapLayers) {
        foreach my $layerID (split(/\s*,\s*/, $mapLayers)) {
            push @layerList, $layerID; 
        }
        my $mapLayerSwitcher = $params->{layerswitcher};
        $mapLayerSwitcher = 'on' unless defined $mapLayerSwitcher;
        $mapLayerSwitcher = ($mapLayerSwitcher eq 'on')?'true':'false';
        push @jsFragment, "mapLayerSwitcher:$mapLayerSwitcher";
    }
   
    my @jsFragments;
    foreach my $layerID (@layerList) {
        my @jsFragment;
        push @jsFragment, "layerID:'$layerID'";

        # layer type
        my $layerType = $params->{$layerID.'_type'};
        push @jsFragment, "layerType:$layerType" if defined $layerType;

        # layer server url
        my $layerURL = $params->{$layerID.'_url'};
        push @jsFragment, "layerURL:$layerURL" if defined $layerURL;

        # layer name
        my $layerName = $params->{$layerID.'_name'};
        push @jsFragment, "layerName:$layerName" if defined $layerName;

        # server params
        my $serverParams = $params->{$layerID.'_serverparams'};
        push @jsFragment, "serverParams:$serverParams" if defined $serverParams;

        # client options
        my $clientOptions = $params->{$layerID.'_clientoptions'};
        push @jsFragment, "clientOptions:$clientOptions" if defined $clientOptions;

        # is base layer
        my $isBaseLayer = $params->{$layerID.'_isbaselayer'};
        $isBaseLayer = 'on' unless defined $isBaseLayer;
        $isBaseLayer = ($isBaseLayer eq 'on')?'true':'false';
        push @jsFragment, "isbaselayer:$isBaseLayer";

        # tile size
        my $tileSize = $params->{$layerID.'_tilesize'};
        push @jsFragment, "tileSize:$tileSize" if defined $tileSize;

        # zoom levels
        my $zoomLevels = $params->{$layerID.'_zoomlevels'};
        push @jsFragment, "zoomlevels:$zoomLevels" if defined $zoomLevels;


        # jsFragment
        push @jsFragments, '{ '.join(', ', @jsFragment).'}';

    }


    push @mapMetadata, 'jsFragments: ['.join(",\n", @jsFragments).']';


    Foswiki::Func::addToZone(
        "script",
        "OpenLayersPlugin/Javascript",
        "<script type='text/javascript'>jQuery(document).ready(function () { init(); });</script>"

  . <<"HERE"
<script type='text/javascript'>

    function init()  {   

        var mapOptions = { maxResolution: 45/512, numZoomLevels: 11, fractionalZoom: true}; 

        var map = new OpenLayers.Map(mapOptions); 

        map.addControl(new OpenLayers.Control.LayerSwitcher({}));

        var layerdemis = new OpenLayers.Layer.WorldWind( "Demis World Map",
            "http://www2.demis.nl/wms/ww.ashx?", 45, 11,
            {T:'WorldMap'}, {tileSize: new OpenLayers.Size(512,512), wrapDateLine:true});
        map.addLayers([layerdemis]);

        var wmslayercoraleco = new OpenLayers.Layer.WMS( "Australian Coral Ecoregions",
            "http://spatial.ala.org.au/geoserver/ALA/wms",
            {layers: "ALA:australian_coral_ecoregions",srs: "EPSG:4326",transparent: "true",format: "image/png"}, {visibility:false, wrapDateLine:true, opacity:0.8});
        map.addLayers([wmslayercoraleco]);

        var wmslayergreatbarrierreef = new OpenLayers.Layer.WMS( "Great Barrier Reef 100m DEM",
            "http://spatial.ala.org.au/geoserver/ALA/wms",
            {layers: "ALA:gbr_gbr100",srs: "EPSG:4326",transparent: "true",format: "image/png"}, {visibility:false, wrapDateLine:true, opacity:0.8});
        map.addLayers([wmslayergreatbarrierreef]); 


        // WW cached
        layer = new OpenLayers.Layer.WorldWind( "World Map (tiles cached)",
        "http://www2.demis.nl/wms/ww.ashx?", 45, 11,
        {T:"WorldMap"}, {tileSize: new OpenLayers.Size(512,512), wrapDateLine:'true' }); 

        var wms_layer_labels = new OpenLayers.Layer.WMS(
            'Labels',
            'http://vmap0.tiles.osgeo.org/wms/vmap0',
            {layers: 'clabel,ctylabel,statelabel',
            transparent:true},
            {wrapDateLine:'true' }
        );

        var style = new OpenLayers.Style({
            pointRadius: "${radius}",
            fillColor: "#ffcc66",
            fillOpacity: 0.8,
            strokeColor: "#cc6633",
            label: "${pointLabel}",
            strokeWidth: "${width}",
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

        var strategy = new OpenLayers.Strategy.Cluster();
        strategy.distance= 20;
        strategy.threshold=2;
        var styleselect = new OpenLayers.Style({fillColor: '#8aeeef',strokeColor: '#32a8a9'});

        var styleMap= new OpenLayers.StyleMap({
            "default": style,
            "select": styleselect }); 

        var vector_layer = new OpenLayers.Layer.Vector('Basic Vector Layer');

        map.addLayers([layer,wms_layer_all,wms_layer_labels, vector_layer]);

        map.addControl(new OpenLayers.Control.EditingToolbar(vector_layer));

        map.render('$mapElement');

        if(!map.getCenter()){
            map.zoomToMaxExtent();
        }


    } 

  </script>
HERE
    );

    my $mapMetadata = '{'.join(",\n", @mapMetadata)."}\n";

    Foswiki::Func::addToZone('script', "OpenLayersPlugin/Javascript::$mapElement", $mapMetadata);

    return "<div id='layerswitcher'></div><div id='$mapElement' style='height:$mapHeightpx; width:$mapWidthpx; position:relative;'></div>";
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
of the License, or (at your option) any later version. For
more details read LICENSE in the root of this distribution.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

As per the GPL, removal of this notice is prohibited.
