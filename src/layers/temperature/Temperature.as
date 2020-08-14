package layers.temperature
{
    import global.Util;

    import graph.Cell;

    public class Temperature
    {
        private var map:Map;

        public function Temperature(map:Map)
        {
            this.map = map;

            for each (var cell:Cell in map.cells)
            {
                cell.temperature = 1 - Math.abs(2 * (cell.point.y / map.height) - 1);
                if (!cell.ocean)
                    cell.temperature -= (cell.elevationAboveSeaLevel) / 2;
                cell.temperature = Util.fixed(cell.temperature, 2);
            }
        }
    }
}