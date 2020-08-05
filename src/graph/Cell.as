package graph
{
    import flash.geom.Point;

    import global.Util;

    import layers.geography.Outflow;
    import layers.geography.River;

    import layers.tectonics.TectonicPlate;

    public class Cell
    {
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
        public var lowestNeighbor:Cell;
        public var flux:Number;
        public var rivers:Vector.<River>;

        // Temperature
        public var temperature:Number;

        public function Cell()
        {
            neighbors = new Vector.<Cell>();
            edges = new Vector.<Edge>();
            corners = new Vector.<Corner>();
        }

        public function get elevationAboveSeaLevel():Number
        {
            return elevation - Map.SEA_LEVEL;
        }

        public function get altitude():Number
        {
            // I know 'altitude' is probably not the perfect word for this, but it's more unique than 'heightWithWater'
            return elevation + water;
        }

        public function get tectonicPlateDirection():int
        {
            return tectonicPlate.direction;
        }

        public function calculateArea():void
        {
            area = 0;
            for each (var edge:Edge in edges)
            {
                var triangleArea:Number = 0;
                if (edge.v0 && edge.v1)
                {
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

        public function sharedEdge(neighbor:Cell):Edge
        {
            for each (var edge:Edge in edges)
            {
                if (edge.d0 == neighbor || edge.d1 == neighbor)
                {
                    return edge;
                }
            }

            return null;
        }
    }
}
