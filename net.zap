opt client_output = "./src/network/client.luau"
opt server_output = "./src/network/server.luau"

opt write_checks = false

type clientProjectileData = struct {
    origin: Vector3,
    direction: Vector3,
    projectileType: u8,
}

type serverProjectileData = struct {
    t: u32,
    origin: Vector3,
    direction: Vector3,
    projectileType: u8,

    sender: u8,
}

event Trojectile_CLIENT = {
    from: Client,
    type: Reliable,
    call: SingleAsync,
    data: clientProjectileData
}

event Trojectile_SERVER = {
    from: Server,
    type: Reliable,
    call: SingleAsync,
    data: serverProjectileData
}