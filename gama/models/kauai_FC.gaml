/***
* Name: kauaiFC
* Author: Chintan Pathak 
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model kauaiFC

/* Insert your model definition here */
global {
	file roads_shapefile <- file("../includes/kauai_highway.shp");
	file ki_evse <- csv_file("../includes/kauai_FC.csv", ",");
	file ki_poi <- csv_file("../includes/kauai_poi.csv", ",");
	graph road_network;
	geometry shape <- envelope(roads_shapefile);
	matrix EVSEData <- matrix(ki_evse);
	matrix POIData <- matrix(ki_poi);
	list<charging_station> all_chargers;
	list<point> pt_rd_cs;
	list<point> pt_ft_cs;
	list<point> verts;
	int ind;
	init {
		// create roads from the shapefile 
		create road from: roads_shapefile;
		road_network <- as_edge_graph(road);
		// Create charging station agents from the EVSEData matrix
		loop j from: 0 to: EVSEData.rows - 1 {
			create charging_station number: 1
			with: [shape ::to_GAMA_CRS({float(EVSEData[5,j]),float(EVSEData[4,j])}, "EPSG:4326"), 
				station_id:: int(EVSEData[6, j]), 
				dcfc_plug_count:: int(EVSEData[3, j]), 
				ev_connector_types :: string(EVSEData[7, j])
				];
			// This is the point on the road network that is closest to the charging station	
			add point(road_network.vertices closest_to (point(to_GAMA_CRS({float(EVSEData[5,j]),float(EVSEData[4,j])}, "EPSG:4326")))) to: pt_rd_cs;
			// This is the farthest point from the previous point, and is the edge of the graph 
			add point(road_network.vertices farthest_to (pt_rd_cs[j])) to: pt_ft_cs;
		}
		
		// Create POI (points of interest) agents
		loop k from: 0 to: POIData.rows - 1 {
			create poi number: 1 
			with: [shape :: to_GAMA_CRS({float(POIData[3,k]), float(POIData[2,k])}, "EPSG:4326")];
		}
		// A list conttaining all chargers
		all_chargers <- (charging_station as list);
		// A list containing all the certices on teh road network
        verts <- road_network.vertices;
       	list<float> distances;
		using topology(road_network) {
		    // Distance between the charging station and Hanalei
			float distance_nr_ft <- distance_to(pt_rd_cs[0], pt_ft_cs[0]);
			write(distance_nr_ft * 0.000621371);
			loop iii from: 0 to: length(verts) - 1 {
				add distance_to(verts[iii], pt_ft_cs[0]) to: distances;	
			}
			ind <- index_of(distances, max(distances));
			write(ind);
			// Distance between Hanalei and Waimea
			write(max(distances) * 0.000621371);
		}
		
	}
	
}

species road {
	geometry display_shape <- line(shape.points, 2.0);

	aspect geom {
		draw shape color: #black;
	}
}

species poi {
	aspect circle {
		draw triangle(1000) color: #green;
	}
}

species charging_station {
	int station_id; // station_id as in AFDC dataset
	int dcfc_plug_count;  // Number of DCFC plugs at the location
	string ev_network;  // Network company that the charging station belongs to, for ex: Blink, ChargePoint etc.
	string ev_connector_types; // Type of connector - CHADEMO (1), COMBO (2), BOTH (3), TESLA (4)
	float max_power;  // max charging power per charging station in kWhr
	float charging_cost; // charging cost in $ per kWhr
	int ev_connector_code; // Codes as indicated in connector_type parenthesis
	rgb cs_color <- #red;
	
		// aspect definitions
	aspect circle {
		draw square(1000) color: cs_color;
	}
}

experiment main type: gui {
	output {
		display KI_network type: opengl {
			species road aspect: geom refresh: false;
			species charging_station aspect: circle refresh: false;
			species poi aspect: circle refresh: false;
            
			// Draw things and text             
            graphics points_display {
            	loop ii from:0 to: length(pt_rd_cs) - 1 {
            		draw circle(500) color:#orange at: pt_ft_cs[ii];
            		draw "Hanalei" at: pt_ft_cs[ii] color: #orange;
            	}
				draw circle(500) color:#purple at: verts[ind];
				draw "Waimea" at: verts[ind] color: #purple;
				draw "charging station" at: all_chargers[0].location color: #red;
				draw "Lihue Airport" at: poi[0].location color: #green;
        	}
		}
	}
}