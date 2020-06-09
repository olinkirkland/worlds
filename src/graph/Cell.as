package graph {
    import flash.geom.Point;

    import global.Util;

    import layers.geography.Outflow;
    import layers.geography.River;

    import layers.tectonics.TectonicPlate;

    public class Cell {
        public var index:int;
        public var used:Boolean;

        // Properties
        public var elevation:Number = 0;


        // Flags
        public var ocean:Boolean = false;

        // Graph
        public var point:Point;
        public var neighbors:Vector.<Cell>;
        public var edges:Vector.<Edge>;
        public var corners:Vector.<Corner>;
        public var area:Number;

        // Lithosphere
        public var tectonicPlate:TectonicPlate;
        public var tectonicPlatePower:Number = Number.NEGATIVE_INFINITY;
        public var tectonicPlateBorder:Boolean;

        // Water Cycle
        public var precipitation:Number;
        public var water:Number = 0;
        public var outflows:Object;
        public var lowestNeighbor:Cell;
        public var flux:Number;
        public var rivers:Vector.<River>;

        // Temperature
        public var temperature:Number;
        public var markForRemoval:Boolean;

        public function Cell() {
            neighbors = new Vector.<Cell>();
            edges = new Vector.<Edge>();
            corners = new Vector.<Corner>();
        }

        public function get elevationAboveSeaLevel():Number {
            return elevation - Map.SEA_LEVEL;
        }

        public function calculateOutflows():void {
            outflows = {};

            var altitudeDifferenceTotal:Number = 0;
            var averageAltitudeOfOutflowNeighbors:Number = 0;

            for each (var neighbor:Cell in neighbors) {
                var altitudeDifference:Number = altitude - neighbor.altitude;

                // Only store positive values (we only care about neighbors with a lower altitude)
                if (altitudeDifference > 0) {
                    var outflow:Outflow = new Outflow();
                    outflow.altitudeDifference = altitudeDifference;
                    outflows[neighbor.index] = outflow;
                    altitudeDifferenceTotal += altitudeDifference;
                    averageAltitudeOfOutflowNeighbors += neighbor.altitude;
                }
            }

            var outflowCount:int = 0;
            for each (outflow in outflows)
                outflowCount++;

            averageAltitudeOfOutflowNeighbors /= outflowCount;

            var totalOutflow:Number = 0;
            for each (outflow in outflows) {
                var m:Number = Math.min(water, altitude - averageAltitudeOfOutflowNeighbors) * (outflow.altitudeDifference / altitudeDifferenceTotal);
                totalOutflow += outflow.water = Math.max(0, m);
            }

            water -= totalOutflow;
        }

        public function calculateInflows():void {
            if (ocean) {
                water = 0;
                return;
            }

            for each (var neighbor:Cell in neighbors) {
                if (neighbor.outflows[index]) {
                    var outflow:Outflow = neighbor.outflows[index];
                    water += outflow.water;
                }
            }
        }

        public function get altitude():Number {
            // I know 'altitude' is probably not the perfect word for this, but it's more unique than 'heightWithWater'
            return elevation + water;
        }

        public function get tectonicPlateDirection():int {
            return tectonicPlate.direction;
        }

        public function removeDuplicateNeighbors():void {
            var before:int = neighbors.length;

            for (var i:int = 0; i < neighbors.length - 1; i++)
                for (var j:int = i + 1; j < neighbors.length; j++)
                    if (neighbors[i] === neighbors[j])
                        neighbors.removeAt(j--);
        }

        public function calculateArea():void {
            area = 0;
            for each (var edge:Edge in edges) {
                var triangleArea:Number = 0;
                if (edge.v0 && edge.v1) {
                    var a:Number = Point.distance(edge.v0.point, point);
                    var b:Number = Point.distance(point, edge.v1.point);
                    var c:Number = Point.distance(edge.v1.point, edge.v0.point);

                    // Use Heron's Formula to determine the triangle's area
                    var p:Number = (a + b + c) / 2;
                    triangleArea = Math.sqrt(p * (p - a) * (p - b) * (p - c));
                }
                area += triangleArea;
            }

            area = Number(area.toFixed(2));
        }

        public function sharedEdge(neighbor:Cell):Edge {
            for each (var edge:Edge in edges) {
                if (edge.d0 == neighbor || edge.d1 == neighbor) {
                    return edge;
                }
            }

            return null;
        }
    }
}
