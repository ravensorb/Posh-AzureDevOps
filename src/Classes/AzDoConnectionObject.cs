using System;
using System.Collections;
using System.Text;
using System.Collections.Generic;

namespace PoshAzDo
{
	public class AzDoConnectObject
	{
		internal AzDoConnectObject()
		{

		}

		public string OrganizationName {get;set;}
		public string ProjectName {get;set;}
		public string OrganizationUrl => string.IsNullOrEmpty(OrganizationName) ? string.Empty : string.Format("https://dev.azure.com/{0}", OrganizationName);
		public string ProjectUrl => string.IsNullOrEmpty(ProjectName) ? string.Empty : string.Format("{0}/{1}", OrganizationUrl, ProjectName);
		public Guid ProjectId {get;set;}
		public string ProjectDescriptor {get;set;}
		public string ReleaseManagementUrl => string.Format("https://vsrm.dev.azure.com/{0}/{1}", OrganizationName, ProjectName);
		public string VsspUrl => string.Format("https://vssps.dev.azure.com/{0}", OrganizationName);
		public string VsaexUrl => string.Format("https://vsaex.dev.azure.com/{0}", OrganizationName);
		public string PAT {get;set;}
		public Dictionary<string, string> HttpHeaders {get;set;} = new Dictionary<string, string>();
		public DateTime CreatedOn {get;set;} = DateTime.Now;
		public bool IsValid => !string.IsNullOrEmpty(OrganizationUrl);

		static public AzDoConnectObject CreateFromUrl(string url)
		{
			var result = new AzDoConnectObject();

			var u = new Uri(url);

			if (u.DnsSafeHost.Contains(".visualstudio.com"))
			{
				result.OrganizationName = u.DnsSafeHost.Split('.')[0];
				result.ProjectName = u.AbsolutePath.Trim('/').Split('/')[0];
			} 
			else if (u.DnsSafeHost.Contains("dev.azure.com"))
			{
				var parts = u.AbsolutePath.Trim('/').Split('/');
				result.OrganizationName = parts[0];
				
				if (parts.Length > 1)
				{
					result.ProjectName = parts[1];
				}                
			}

			System.Diagnostics.Debug.WriteLine(result.ToString());

			return result;
		}

		internal new string ToString()
		{
			var sb = new StringBuilder();

			sb.AppendFormat("Organziation Name: {0}", OrganizationName);
			sb.AppendLine();
			sb.AppendFormat("Organziation Name: {0}", OrganizationUrl);
			sb.AppendLine();
			sb.AppendFormat("Project Name: {0}", ProjectName);
			sb.AppendLine();
			sb.AppendFormat("Project Id: {0}", ProjectId);
			sb.AppendLine();
			sb.AppendFormat("Project Descriptor: {0}", ProjectDescriptor);
			sb.AppendLine();
			sb.AppendFormat("Project Url: {0}", ProjectUrl);
			sb.AppendLine();
			sb.AppendFormat("Release Management Url: {0}", ReleaseManagementUrl);
			sb.AppendLine();
			sb.AppendFormat("CreatedOn: {0}", CreatedOn.ToString());
			sb.AppendLine();

			return sb.ToString();
		}
	}
}
