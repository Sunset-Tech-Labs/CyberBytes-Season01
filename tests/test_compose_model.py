import json
import subprocess
import unittest


def load_model():
    result = subprocess.run(
        ["docker", "compose", "-f", "compose.yaml", "config", "--format", "json"],
        check=True,
        capture_output=True,
        text=True,
    )
    return json.loads(result.stdout)


class ComposeModelTests(unittest.TestCase):
    def test_topology_and_containment(self):
        model = load_model()
        services = model["services"]
        self.assertEqual(set(services), {"attacker", "perimeter", "operations", "vault"})
        self.assertEqual(set(services["attacker"]["networks"]), {"dmz"})
        self.assertEqual(set(services["perimeter"]["networks"]), {"dmz", "operations_lan"})
        self.assertEqual(set(services["operations"]["networks"]), {"operations_lan", "research_lan"})
        self.assertEqual(set(services["vault"]["networks"]), {"research_lan"})
        for service in services.values():
            self.assertFalse(service.get("ports"))
            self.assertFalse(service.get("privileged", False))
            self.assertNotIn("/var/run/docker.sock", json.dumps(service.get("volumes", [])))
        self.assertTrue(all(network["internal"] for network in model["networks"].values()))

    def test_static_addresses(self):
        model = load_model()["services"]
        self.assertEqual(model["attacker"]["networks"]["dmz"]["ipv4_address"], "172.30.10.20")
        self.assertEqual(model["perimeter"]["networks"]["dmz"]["ipv4_address"], "172.30.10.10")
        self.assertEqual(model["perimeter"]["networks"]["operations_lan"]["ipv4_address"], "172.30.20.10")
        self.assertEqual(model["operations"]["networks"]["operations_lan"]["ipv4_address"], "172.30.20.20")
        self.assertEqual(model["operations"]["networks"]["research_lan"]["ipv4_address"], "172.30.30.10")
        self.assertEqual(model["vault"]["networks"]["research_lan"]["ipv4_address"], "172.30.30.20")


if __name__ == "__main__":
    unittest.main()
