#!/usr/bin/env python3
"""
Performance Testing Script for Fountain Map API
Tests various endpoints and measures response times for different query patterns.
"""

import requests
import time
import statistics
import json
from typing import List, Dict, Any
import argparse
import concurrent.futures
from datetime import datetime

class PerformanceTester:
    def __init__(self, base_url: str):
        self.base_url = base_url.rstrip('/')
        self.session = requests.Session()
        
    def test_endpoint(self, endpoint: str, method: str = 'GET', data: Dict = None, params: Dict = None) -> Dict[str, Any]:
        """Test a single endpoint and measure performance"""
        url = f"{self.base_url}{endpoint}"
        
        start_time = time.time()
        try:
            if method.upper() == 'GET':
                response = self.session.get(url, params=params, timeout=30)
            elif method.upper() == 'POST':
                response = self.session.post(url, json=data, timeout=30)
            else:
                raise ValueError(f"Unsupported method: {method}")
            
            end_time = time.time()
            response_time = (end_time - start_time) * 1000  # Convert to milliseconds
            
            return {
                'endpoint': endpoint,
                'method': method,
                'status_code': response.status_code,
                'response_time_ms': response_time,
                'response_size_bytes': len(response.content),
                'success': response.status_code == 200,
                'error': None if response.status_code == 200 else response.text[:200]
            }
            
        except Exception as e:
            end_time = time.time()
            response_time = (end_time - start_time) * 1000
            
            return {
                'endpoint': endpoint,
                'method': method,
                'status_code': None,
                'response_time_ms': response_time,
                'response_size_bytes': 0,
                'success': False,
                'error': str(e)
            }
    
    def test_geohash_queries(self, test_count: int = 10) -> List[Dict[str, Any]]:
        """Test geohash-based queries with different precision levels"""
        print("Testing geohash-based queries...")
        
        # Test different geohash precision levels
        geohash_prefixes = ['d', 'dr', 'dr5', 'dr5r', 'dr5ru', 'dr5ruj']
        results = []
        
        for prefix in geohash_prefixes:
            print(f"  Testing geohash prefix: {prefix}")
            for i in range(test_count):
                result = self.test_endpoint(
                    f"/fountains/geohash/{prefix}",
                    params={'limit': 100}
                )
                result['geohash_prefix'] = prefix
                results.append(result)
                
                # Small delay between requests
                time.sleep(0.1)
        
        return results
    
    def test_viewport_queries(self, test_count: int = 10) -> List[Dict[str, Any]]:
        """Test viewport-based queries with different zoom levels"""
        print("Testing viewport-based queries...")
        
        # Test different zoom levels and viewport sizes
        test_cases = [
            # (zoom_level, north, south, east, west, description)
            (3, 90, -90, 180, -180, "World view"),
            (8, 45, 35, 15, 5, "Europe view"),
            (12, 40.8, 40.7, -74.0, -74.1, "NYC area"),
            (16, 40.7589, 40.7588, -73.9851, -73.9852, "Times Square"),
        ]
        
        results = []
        
        for zoom_level, north, south, east, west, description in test_cases:
            print(f"  Testing {description} (zoom {zoom_level})")
            for i in range(test_count):
                result = self.test_endpoint(
                    "/fountains/viewport",
                    method='POST',
                    data={
                        'north': north,
                        'south': south,
                        'east': east,
                        'west': west,
                        'zoom_level': zoom_level,
                        'limit': 500
                    }
                )
                result['viewport_description'] = description
                result['zoom_level'] = zoom_level
                results.append(result)
                
                # Small delay between requests
                time.sleep(0.1)
        
        return results
    
    def test_search_queries(self, test_count: int = 10) -> List[Dict[str, Any]]:
        """Test text search functionality"""
        print("Testing search queries...")
        
        search_terms = ['fountain', 'drinking', 'water', 'park', 'public']
        results = []
        
        for term in search_terms:
            print(f"  Testing search term: '{term}'")
            for i in range(test_count):
                result = self.test_endpoint(
                    "/fountains/search",
                    params={'query': term, 'limit': 100}
                )
                result['search_term'] = term
                results.append(result)
                
                # Small delay between requests
                time.sleep(0.1)
        
        return results
    
    def test_concurrent_requests(self, endpoint: str, concurrent_users: int = 10, requests_per_user: int = 5) -> List[Dict[str, Any]]:
        """Test concurrent load on an endpoint"""
        print(f"Testing concurrent load: {concurrent_users} users, {requests_per_user} requests each")
        
        def make_requests():
            user_results = []
            for i in range(requests_per_user):
                result = self.test_endpoint(endpoint, params={'limit': 100})
                user_results.append(result)
                time.sleep(0.1)
            return user_results
        
        all_results = []
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=concurrent_users) as executor:
            futures = [executor.submit(make_requests) for _ in range(concurrent_users)]
            
            for future in concurrent.futures.as_completed(futures):
                user_results = future.result()
                all_results.extend(user_results)
        
        return all_results
    
    def run_comprehensive_test(self, test_count: int = 10, concurrent_users: int = 10) -> Dict[str, Any]:
        """Run comprehensive performance test suite"""
        print("Starting comprehensive performance test...")
        print(f"Base URL: {self.base_url}")
        print(f"Test count per endpoint: {test_count}")
        print(f"Concurrent users: {concurrent_users}")
        print("-" * 50)
        
        start_time = time.time()
        
        # Run all test suites
        geohash_results = self.test_geohash_queries(test_count)
        viewport_results = self.test_viewport_queries(test_count)
        search_results = self.test_search_queries(test_count)
        
        # Test concurrent load on geohash endpoint
        concurrent_results = self.test_concurrent_requests(
            "/fountains/geohash/dr5", 
            concurrent_users, 
            max(1, test_count // concurrent_users)
        )
        
        end_time = time.time()
        total_test_time = end_time - start_time
        
        # Compile results
        all_results = {
            'test_info': {
                'base_url': self.base_url,
                'test_count': test_count,
                'concurrent_users': concurrent_users,
                'total_test_time_seconds': total_test_time,
                'timestamp': datetime.now().isoformat()
            },
            'geohash_tests': geohash_results,
            'viewport_tests': viewport_results,
            'search_tests': search_results,
            'concurrent_tests': concurrent_results,
            'summary': self.generate_summary(
                geohash_results, viewport_results, search_results, concurrent_results
            )
        }
        
        return all_results
    
    def generate_summary(self, *test_result_lists) -> Dict[str, Any]:
        """Generate summary statistics for all test results"""
        all_results = []
        for result_list in test_result_lists:
            all_results.extend(result_list)
        
        successful_results = [r for r in all_results if r['success']]
        failed_results = [r for r in all_results if not r['success']]
        
        if not successful_results:
            return {
                'total_tests': len(all_results),
                'successful_tests': 0,
                'failed_tests': len(failed_results),
                'success_rate': 0.0,
                'error_details': [r['error'] for r in failed_results if r['error']]
            }
        
        response_times = [r['response_time_ms'] for r in successful_results]
        response_sizes = [r['response_size_bytes'] for r in successful_results]
        
        return {
            'total_tests': len(all_results),
            'successful_tests': len(successful_results),
            'failed_tests': len(failed_results),
            'success_rate': len(successful_results) / len(all_results) * 100,
            'response_time_stats': {
                'min_ms': min(response_times),
                'max_ms': max(response_times),
                'mean_ms': statistics.mean(response_times),
                'median_ms': statistics.median(response_times),
                'std_dev_ms': statistics.stdev(response_times) if len(response_times) > 1 else 0
            },
            'response_size_stats': {
                'min_bytes': min(response_sizes),
                'max_bytes': max(response_sizes),
                'mean_bytes': statistics.mean(response_sizes),
                'median_bytes': statistics.median(response_sizes)
            },
            'error_details': [r['error'] for r in failed_results if r['error']]
        }
    
    def print_summary(self, summary: Dict[str, Any]):
        """Print formatted summary of test results"""
        print("\n" + "=" * 60)
        print("PERFORMANCE TEST SUMMARY")
        print("=" * 60)
        
        print(f"Total Tests: {summary['total_tests']}")
        print(f"Successful: {summary['successful_tests']}")
        print(f"Failed: {summary['failed_tests']}")
        print(f"Success Rate: {summary['success_rate']:.1f}%")
        
        if summary['successful_tests'] > 0:
            print("\nResponse Time Statistics (milliseconds):")
            rt = summary['response_time_stats']
            print(f"  Min: {rt['min_ms']:.2f}")
            print(f"  Max: {rt['max_ms']:.2f}")
            print(f"  Mean: {rt['mean_ms']:.2f}")
            print(f"  Median: {rt['median_ms']:.2f}")
            print(f"  Std Dev: {rt['std_dev_ms']:.2f}")
            
            print("\nResponse Size Statistics (bytes):")
            rs = summary['response_size_stats']
            print(f"  Min: {rs['min_bytes']}")
            print(f"  Max: {rs['max_bytes']}")
            print(f"  Mean: {rs['mean_bytes']:.0f}")
            print(f"  Median: {rs['median_bytes']}")
        
        if summary['error_details']:
            print(f"\nErrors ({len(summary['error_details'])}):")
            for error in summary['error_details'][:5]:  # Show first 5 errors
                print(f"  - {error}")
            if len(summary['error_details']) > 5:
                print(f"  ... and {len(summary['error_details']) - 5} more errors")
        
        print("=" * 60)

def main():
    parser = argparse.ArgumentParser(description='Performance test for Fountain Map API')
    parser.add_argument('base_url', help='Base URL of the API (e.g., http://localhost:8000)')
    parser.add_argument('--test-count', type=int, default=10, help='Number of tests per endpoint (default: 10)')
    parser.add_argument('--concurrent-users', type=int, default=10, help='Number of concurrent users (default: 10)')
    parser.add_argument('--output-file', help='Save results to JSON file')
    parser.add_argument('--quick-test', action='store_true', help='Run quick test with fewer iterations')
    
    args = parser.parse_args()
    
    if args.quick_test:
        args.test_count = 3
        args.concurrent_users = 3
        print("Running quick test mode...")
    
    # Initialize tester
    tester = PerformanceTester(args.base_url)
    
    try:
        # Run comprehensive test
        results = tester.run_comprehensive_test(
            test_count=args.test_count,
            concurrent_users=args.concurrent_users
        )
        
        # Print summary
        tester.print_summary(results['summary'])
        
        # Save results if requested
        if args.output_file:
            with open(args.output_file, 'w') as f:
                json.dump(results, f, indent=2)
            print(f"\nDetailed results saved to: {args.output_file}")
        
        # Exit with error code if tests failed
        if results['summary']['failed_tests'] > 0:
            exit(1)
            
    except KeyboardInterrupt:
        print("\nTest interrupted by user")
        exit(1)
    except Exception as e:
        print(f"Test failed with error: {e}")
        exit(1)

if __name__ == "__main__":
    main()

