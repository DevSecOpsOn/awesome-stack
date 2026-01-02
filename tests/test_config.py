#!/usr/bin/env python3
"""
E2E Test Configuration for Docker Stacks
"""

import os
import time
import requests
import docker
from pathlib import Path

class DockerStackTester:
    def __init__(self):
        self.client = docker.from_env()
        self.base_url = "http://localhost"
        self.timeout = 300  # 5 minutes

    def wait_for_service(self, service_name, expected_replicas=1):
        """Wait for a service to be ready"""
        print(f"Waiting for service {service_name} to be ready...")

        start_time = time.time()
        while time.time() - start_time < self.timeout:
            try:
                service = self.client.services.get(service_name)
                tasks = service.tasks()

                running_tasks = [t for t in tasks if t['Status']['State'] == 'running']

                if len(running_tasks) >= expected_replicas:
                    print(f"✅ Service {service_name} is ready")
                    return True

                print(f"Service {service_name}: {len(running_tasks)}/{expected_replicas} replicas ready")
                time.sleep(10)

            except Exception as e:
                print(f"Error checking service {service_name}: {e}")
                time.sleep(10)

        print(f"❌ Timeout waiting for service {service_name}")
        return False

    def test_service_health(self, service_name, port, path="/", expected_status=200):
        """Test if a service is responding to HTTP requests"""
        url = f"{self.base_url}:{port}{path}"

        try:
            response = requests.get(url, timeout=10)
            if response.status_code == expected_status:
                print(f"✅ Service {service_name} health check passed")
                return True
            else:
                print(f"❌ Service {service_name} returned status {response.status_code}")
                return False
        except Exception as e:
            print(f"❌ Service {service_name} health check failed: {e}")
            return False

    def run_basic_tests(self):
        """Run basic tests for essential services"""
        tests = [
            ("traefik_traefik", 8080, "/api/rawdata"),
            ("portainer_portainer", 9000, "/"),
        ]

        all_passed = True

        for service_name, port, path in tests:
            if not self.wait_for_service(service_name):
                all_passed = False
                continue

            # Give service extra time to fully start
            time.sleep(30)

            if not self.test_service_health(service_name, port, path):
                all_passed = False

        return all_passed

if __name__ == "__main__":
    tester = DockerStackTester()

    print("🧪 Starting Docker Stack E2E Tests...")

    if tester.run_basic_tests():
        print("🎉 All E2E tests passed!")
        exit(0)
    else:
        print("❌ Some E2E tests failed!")
        exit(1)
