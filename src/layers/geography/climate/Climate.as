package layers.geography.climate
{
    import global.Util;

    import graph.Cell;

    public class Climate
    {
        private var map:Map;

        private var temperatureLevelsDefinitions:Array;
        private var moistureLevelDefinitions:Array;

        private static const cold:String = "cold";
        private static const temperate:String = "temperate";
        private static const hot:String = "hot";

        private static const arid:String = "arid";
        private static const dry:String = "dry";
        private static const humid:String = "humid";
        private static const wet:String = "wet";

        public function Climate(map:Map)
        {
            this.map = map;

            // Determine temperature
            for each (var cell:Cell in map.cells)
            {
                cell.temperature = 1 - Math.abs(2 * (cell.point.y / map.height) - 1) * 1.2;
                if (!cell.ocean)
                    cell.temperature -= (cell.elevationAboveSeaLevel);
                cell.temperature = Util.fixed(cell.temperature, 2);
                cell.temperature = Math.min(Math.max(0, cell.temperature), 1);
            }

            // Determine biomes
            temperatureLevelsDefinitions = [
                {name: cold, minimum: 0, maximum: .3},
                {name: temperate, minimum: .3, maximum: .9},
                {name: hot, minimum: .9, maximum: 1}
            ];

            moistureLevelDefinitions = [
                {name: arid, minimum: 0, maximum: .05},
                {name: dry, minimum: .05, maximum: .3},
                {name: humid, minimum: .3, maximum: .8},
                {name: wet, minimum: .8, maximum: 1}
            ];

            for each (cell in map.cells)
                assignBiomeTypeToCell(cell);
        }

        private function assignBiomeTypeToCell(cell:Cell):void
        {
            /**
             * Determines a biome from a cell's defaultProperties
             */

            if (cell.ocean)
                cell.biomeType = Biome.OCEAN;

            var t:String = null;
            for each (var temperatureLevel:Object in temperatureLevelsDefinitions)
                if (cell.temperature >= temperatureLevel.minimum && cell.temperature <= temperatureLevel.maximum)
                    t = temperatureLevel.name;
            cell.temperatureLevel = t;

            var m:String = null;
            for each (var moistureLevel:Object in moistureLevelDefinitions)
                if (cell.moisture >= moistureLevel.minimum && cell.moisture <= moistureLevel.maximum)
                    m = moistureLevel.name;
            cell.moistureLevel = m;

            var type:String = null;

            switch (t)
            {
                case cold:
                    if (m == arid || m == dry) type = Biome.TUNDRA;
                    else if (m == humid || m == wet) type = Biome.BOREAL_FOREST;
                    break;

                case temperate:
                    if (m == arid) type = Biome.GRASSLAND;
                    else if (m == dry) type = Biome.SHRUBLAND;
                    else if (m == humid) type = Biome.SEASONAL_FOREST;
                    else if (m == wet) type = Biome.TEMPERATE_RAINFOREST;
                    break;

                case hot:
                    if (m == arid) type = Biome.DESERT;
                    else if (m == dry) type = Biome.SAVANNA;
                    else if (m == humid || m == wet) type = Biome.TROPICAL_RAINFOREST;
                    break;
            }

            cell.biomeType = type;
        }
    }
}