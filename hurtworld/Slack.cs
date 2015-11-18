// Reference: Pathfinding.JsonFx

using System.Text;
//using Newtonsoft.Json;
using Pathfinding.Serialization.JsonFx;
using Oxide.Core;
using Oxide.Core.Libraries;

namespace Oxide.Plugins
{
    [Info("Slack", "Wulf/lukespragg", "0.1.0", ResourceId = 0)]
    [Description("Enables notifications via Slack.")]

    public class Slack : HurtworldPlugin
    {
        readonly WebRequests web = Interface.Oxide.GetLibrary<WebRequests>("WebRequests");

        void OnPlayerChat(PlayerIdentity player, uLink.NetworkMessageInfo info, string message)
        {
            // Check for blank/empty message
            if (string.IsNullOrEmpty(message)) return;

            // Configuration
            // TODO: Create actual config file
            //var token = "";
            var url = "https://hooks.slack.com/services/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";
            var name = "The Wulf Den";
            var link_names = true;
            var icon_url = "https://wulf.im/uploads/site-logo.png";

            // Format the request
            var slackRequestObject = new SlackRequestObject()
            {
                username = name,
                text = message, // TODO: Check for @user and make lowercase
                link_names = link_names == true ? "1" : "0",
                icon_url = icon_url
            };
            var stringBuilder = new StringBuilder();
            (new JsonWriter(stringBuilder)).Write(slackRequestObject);

            // Post to Slack
            web.EnqueuePost(url, stringBuilder.ToString(), WebRequestCallback, this);
        }

        void WebRequestCallback(int code, string response)
        {
            if (response != null && code == 200) return;
            Puts("Couldn't get an answer from Slack!");
        }

        // More info: https://api.slack.com/methods/chat.postMessage
        public class SlackRequestObject
        {
            public string token; // Authentication token (Requires scope: post)
            public string channel; //  Channel, private group, or IM channel to send message to. Can be an encoded ID, or a name.
            public string text; // Text of the message to send.See below for an explanation of formatting.
            public string username; // Name of bot.
            public string as_user; // Pass true to post the message as the authed user, instead of as a bot
            public string parse; // Change how messages are treated. See below.
            public string link_names; // Find and link channel names and usernames.
            public string attachments; // Structured message attachments.
            public string unfurl_links; // Pass true to enable unfurling of primarily text-based content.
            public string unfurl_media; // Pass false to disable unfurling of media content.
            public string icon_url; // URL to an image to use as the icon for this message
            public string icon_emoji; // Emoji to use as the icon for this message. Overrides icon_url.
        }
    }
}
