using System;

namespace HelloWorldApp
{
    public partial class Default : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            litServerName.Text = Environment.MachineName;
            litServerTime.Text = DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss");
            litBuildTag.Text = System.Configuration.ConfigurationManager.AppSettings["BuildTag"] ?? "local";
        }
    }
}
