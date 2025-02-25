pub const Tile = struct {
    impassable: bool = false,

    pub fn init(impassable: bool) Tile {
        return Tile{ .impassable = impassable };
    }

    pub fn empty() Tile {
        return Tile.init(false);
    }
};
