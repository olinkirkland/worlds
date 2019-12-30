package layers {
    import flash.geom.Point;
    import flash.geom.Rectangle;

    import global.Global;

    import graph.Cell;

    import global.Rand;
    import global.Util;

    public class TectonicPlate {
        // Types
        public static var CONTINENTAL:String = "continentalPlate";
        public static var OCEANIC:String = "oceanicPlate";

        // Properties
        public var index:int;
        public var bounds:Rectangle;
        public var centroid:Point;
        public var type:String;
        public var color:uint;
        public var cells:Vector.<Cell>;
        public var area:Number;
        public var areaPercent:Number;
        public var direction:int;

        public function TectonicPlate(index:int):void {
            this.index = index;

            cells = new Vector.<Cell>();

            color = Global.rand.next() * 0xffffff;

            direction = Global.rand.between(0, 360);
        }

        public function addCell(cell:Cell):void {
            cell.tectonicPlate = this;
            cells.push(cell);
        }

        public function removeCell(cell:Cell):void {
            cell.tectonicPlate = null;
            for (var i:int = 0; i < cells.length; i++) {
                if (cells[i] == cell) {
                    cells.removeAt(i);
                    break;
                }
            }
        }

        public function calculateArea():void {
            area = 0;
            for each (var cell:Cell in cells)
                area += cell.area;
            area = Util.round(area);
        }
    }
}