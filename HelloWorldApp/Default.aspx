<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="HelloWorldApp.Default" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Hello World - ASP.NET 4.8.1</title>
</head>
<body style="font-family: Segoe UI, Arial, sans-serif; text-align: center; margin-top: 80px;">
    <form id="form1" runat="server">
        <div>
            <h1>Hola Mundo Team Synapsis</h1>
            <p>ASP.NET Framework 4.8.1 corriendo en IIS</p>
            <p>Servidor: <asp:Literal ID="litServerName" runat="server" /></p>
            <p>Hora del servidor: <asp:Literal ID="litServerTime" runat="server" /></p>
            <p>Versión de despliegue: <asp:Literal ID="litBuildTag" runat="server" /></p>
        </div>
    </form>
</body>
</html>

<%--#'Este es un proyecto visual.net fmk 4.8.1 lo vamos a deployar en aws, con ayuda de github y los runners...--%>