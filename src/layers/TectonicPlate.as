package layers {
    import graph.Cell;

    import mx.utils.UIDUtil;

    import util.Rand;

    public class TectonicPlate {
        public var index:int;
        public var color:uint;
        public var cells:Vector.<Cell>;

        public function TectonicPlate(index:int):void {
            this.index = index;
            color = new Rand(index*99).next() * 0xffffff;

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
    }
}
