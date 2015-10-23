// For development use only!

namespace Oxide.Plugins
{
    [Info("Protocol", "Wulf/lukespragg", 0.1)]
    [Description("Allows any client, regardless of protocol, to connect.")]

    class Protocol : RustPlugin
    {
        void OnClientAuth(Network.Message pack)
        {
            if (pack.connection == null) return;

            Puts($"{pack.connection.userid} joined with protocol {pack.connection.protocol}");
            pack.connection.protocol = Rust.Protocol.network;
        }
    }
}
