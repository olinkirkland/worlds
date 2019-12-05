package graph {
    import flash.geom.Point;

    import layers.TectonicPlate;

    public class Cell {
        public var index:int;
        public var used:Boolean;

        //temp
        public var fragment:Boolean;

        // Graph
        public var point:Point;
        public var neighbors:Vector.<Cell>;
        public var edges:Vector.<Edge>;
        public var corners:Vector.<Corner>;

        // Lithosphere
        public var tectonicPlate:TectonicPlate;
        public var tectonicPlatePower:Number = 0;

        public function Cell() {
            neighbors = new Vector.<Cell>();
            edges = new Vector.<Edge>();
            corners = new Vector.<Corner>();
        }
    }
}
