using System;
using System.Collections.Generic;

namespace PoshAzDo
{
    public class AzDoConnectObject
    {
        public string OrganizationUrl {get;set;}
        public string ProjectName {get;set;}
        public string ProjectUrl {get;set;}
        public string ReleaseManagementUrl {get;set;}
        public string PAT {get;set;}
        public Dictionary<string, string> HttpHeaders {get;set;}
        public DateTime CreatedOn {get;set;} = DateTime.Now;
   }
}
