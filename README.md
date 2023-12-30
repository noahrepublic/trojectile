## The Idea

on client request to fire, the clients receive a timestamp on when the projectile started according to the server, and has access to each projectile type speeds and whatever.

then to know how far progressed the projectile is for visuals it is just, game.Workspace:GetServerTimeNow() - timestamp
a rollback system would also be easily achievable with this approach for any ping compensation

bullets could be on a different step instead of 60hz something like 30 or 20