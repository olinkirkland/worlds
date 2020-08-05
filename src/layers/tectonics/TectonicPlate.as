package layers.tectonics
{
    import global.Rand;
    import global.Util;

    import graph.Cell;

    public class TectonicPlate
    {
        // Types
        public static const CONTINENTAL:String = "continentalPlate";
        public static const OCEANIC:String     = "oceanicPlate";
        public static const DEEP:String        = "deepPlate";

        // Properties
        public var index:int;
        public var type:String;
        public var color:uint;
        public var cells:Vector.<Cell>;
        public var area:Number;
        public var areaPercent:Number;
        public var direction:int;

        public function TectonicPlate(index:int):void
        {
            this.index = index;

            cells     = new Vector.<Cell>();
            color     = Rand.rand.next() * 0xffffff;
            direction = Rand.rand.between(0, 360);
        }

        public function addCell(cell:Cell):void
        {
            cell.tectonicPlate = this;
            cells.push(cell);
        }

        public function removeCell(cell:Cell):void
        {
            cell.tectonicPlate = null;
            for (var i:int = 0; i < cells.length; i++)
            {
                if (cells[i] == cell)
                {
                    cells.removeAt(i);
                    break;
                }
            }
        }

        public function calculateArea():void
        {
            area = 0;
            for each (var cell:Cell in cells)
                area += cell.area;
            area = Util.round(area);
        }
    }
}