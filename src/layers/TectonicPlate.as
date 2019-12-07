package layers {
    import graph.Cell;

    import mx.utils.UIDUtil;

    import util.Rand;
    import util.Util;

    public class TectonicPlate {
        public var index:int;
        public var color:uint;
        public var cells:Vector.<Cell>;
        public var area:Number;
        public var areaPercent:Number;

        public function TectonicPlate(index:int):void {
            this.index = index;
            color = new Rand(index * 99).next() * 0xffffff;

            cells = new Vector.<Cell>();
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