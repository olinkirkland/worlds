package layers {
public class Wind {
    private var map:Map;

    public static const FROM_NORTH_WEST:String = "north-west";
    public static const FROM_SOUTH_WEST:String = "south-west";
    public static const FROM_NORTH_EAST:String = "north-east";
    public static const FROM_SOUTH_EAST:String = "south-east";

    public var direction:String;
    public var windParticles:Vector.<WindParticle>;

    public function Wind(map:Map, direction:String) {
        this.direction = direction;
        // Determine where to spawn the wind particles
        var firstDirection:String = direction.split("-")[0];
        var secondDirection:String = direction.split("-")[1];
    }
}
}
