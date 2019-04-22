using FluentAssertions;
using NUnit.Framework;
using PoshAzDo;

namespace Tests
{
	public class AzDoConnectionObjectTests
	{
		[SetUp]
		public void Setup()
		{
		}

		[Test]
		public void ValidClassicOrganizationUrlParseTest()
		{
			var conn = AzDoConnectObject.CreateFromUrl("https://3pager.visualstudio.com");

			conn.OrganizationName.Should().BeEquivalentTo("3pager");
			conn.ProjectName.Should().BeNullOrEmpty();
			conn.OrganizationUrl.Should().BeEquivalentTo("https://dev.azure.com/3pager");
			conn.ProjectUrl.Should().BeNullOrEmpty();
		}

		[Test]
		public void InValidClassicOrganizationUrlParseTest()
		{
			var conn = AzDoConnectObject.CreateFromUrl("https://visualstudio.com/3pager/3pager");

			conn.OrganizationName.Should().BeNullOrEmpty();
			conn.ProjectName.Should().BeNullOrEmpty();
			conn.OrganizationUrl.Should().BeNullOrEmpty();
			conn.ProjectUrl.Should().BeNullOrEmpty();
		}

		[Test]
		public void ValidClassicProjectUrlParseTest()
		{
			var conn = AzDoConnectObject.CreateFromUrl("https://3pager.visualstudio.com/3pager");

			conn.OrganizationName.Should().BeEquivalentTo("3pager");
			conn.ProjectName.Should().BeEquivalentTo("3pager");
			conn.OrganizationUrl.Should().BeEquivalentTo("https://dev.azure.com/3pager");
			conn.ProjectUrl.Should().BeEquivalentTo("https://dev.azure.com/3Pager/3pager");
		}

		[Test]
		public void ValidOrganizationUrlParseTest()
		{
			var conn = AzDoConnectObject.CreateFromUrl("https://dev.azure.com/3pager/");

			conn.OrganizationName.Should().BeEquivalentTo("3pager");
			conn.ProjectName.Should().BeNullOrEmpty();
			conn.OrganizationUrl.Should().BeEquivalentTo("https://dev.azure.com/3pager");
			conn.ProjectUrl.Should().BeNullOrEmpty();
		}

		[Test]
		public void ValidProjectUrlParseTest()
		{
			var conn = AzDoConnectObject.CreateFromUrl("https://dev.azure.com/3pager/3pager");

			conn.OrganizationName.Should().BeEquivalentTo("3pager");
			conn.ProjectName.Should().BeEquivalentTo("3pager");
			conn.OrganizationUrl.Should().BeEquivalentTo("https://dev.azure.com/3pager");
			conn.ProjectUrl.Should().BeEquivalentTo("https://dev.azure.com/3Pager/3pager");
		}
	}
}