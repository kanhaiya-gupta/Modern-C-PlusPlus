# Practice Questions (Coding Interviews)

Practice problems using **vectors**, **ranges**, **lambdas**, **lazy evaluation**, **std::map**, and **std::unordered_map**—common in C++ coding interviews. Each section has problems with a short approach and a solution sketch or full example in modern C++. Try solving yourself first, then compare. For a full list of vector operations see [Vector Reference](vector-reference.md). For 2D vectors and matrix problems see section 6. See also [Containers](containers.md), [STL Containers](stl-containers.md), [Ranges & Views](ranges-and-views.md), [Lambdas](lambdas.md), [Lazy evaluation](lazy-evaluation.md).

---

## 1. Vectors

### 1.1 Two Sum (indices)

**Problem:** Given an array of integers and a target, return indices of two numbers that add up to target. Assume exactly one solution.

**Example:** `nums = [2, 7, 11, 15]`, `target = 9` → `[0, 1]`

**Approach:** Use **unordered_map** (value → index). For each `nums[i]`, check if `target - nums[i]` exists in the map; if yes return the two indices. See section 5.1 for the map-based solution.

---

### 1.2 Remove duplicates (keep first occurrence)

**Problem:** Given a sorted vector, remove duplicates in place and return the new length. Result should be in the first `len` elements.

**Example:** `[1, 1, 2, 2, 3]` → length 3, vector starts with `[1, 2, 3, ...]`

**Solution (ranges, C++20):**

```cpp
#include <vector>
#include <algorithm>
#include <ranges>

int removeDuplicates(std::vector<int>& nums) {
    auto it = std::unique(nums.begin(), nums.end());
    return static_cast<int>(it - nums.begin());
}
```

Or with **std::ranges::unique** and **erase**:

```cpp
#include <ranges>
auto end = std::ranges::unique(nums).begin();
nums.erase(end, nums.end());
return static_cast<int>(nums.size());
```

---

### 1.3 Running sum (prefix sum)

**Problem:** Replace each element with the sum of all elements up to and including it.

**Example:** `[1, 2, 3, 4]` → `[1, 3, 6, 10]`

**Solution (ranges / loop):**

```cpp
#include <vector>
#include <ranges>

std::vector<int> runningSum(std::vector<int>& nums) {
    int sum = 0;
    for (int& x : nums) {
        sum += x;
        x = sum;
    }
    return nums;
}
```

---

### 1.4 Merge two sorted vectors

**Problem:** Merge two sorted vectors into one sorted vector.

**Solution (std::merge):**

```cpp
#include <vector>
#include <algorithm>

std::vector<int> mergeSorted(const std::vector<int>& a, const std::vector<int>& b) {
    std::vector<int> out;
    out.reserve(a.size() + b.size());
    std::merge(a.begin(), a.end(), b.begin(), b.end(), std::back_inserter(out));
    return out;
}
```

---

### 1.5 K largest elements

**Problem:** Given a vector and integer k, return the k largest elements (order doesn’t matter).

**Solution (partial_sort or nth_element):**

```cpp
#include <vector>
#include <algorithm>

std::vector<int> kLargest(std::vector<int> nums, int k) {
    k = std::min(k, static_cast<int>(nums.size()));
    std::nth_element(nums.begin(), nums.begin() + k, nums.end(), std::greater{});
    return std::vector<int>(nums.begin(), nums.begin() + k);
}
```

---

## 2. Ranges and lambdas

### 2.1 Filter evens, then square (pipeline)

**Problem:** From a vector of integers, take only even numbers and return their squares.

**Example:** `[1, 2, 3, 4, 5]` → `[4, 16]`

**Solution (C++20 views, lazy):**

```cpp
#include <ranges>
#include <vector>
#include <iostream>

int main() {
    std::vector<int> v = {1, 2, 3, 4, 5};
    auto evens_squared = v
        | std::views::filter([](int x) { return x % 2 == 0; })
        | std::views::transform([](int x) { return x * x; });
    std::vector<int> result(evens_squared.begin(), evens_squared.end());
    // result == {4, 16}
}
```

---

### 2.2 Sort by custom comparator (lambda)

**Problem:** Sort a vector of pairs by the second element (ascending); if equal, by the first (descending).

**Solution:**

```cpp
#include <vector>
#include <algorithm>

std::vector<std::pair<int, int>> pairs = {{1, 2}, {2, 2}, {3, 1}};
std::ranges::sort(pairs, [](const auto& a, const auto& b) {
    if (a.second != b.second) return a.second < b.second;
    return a.first > b.first;
});
```

---

### 2.3 First N from infinite sequence (lazy)

**Problem:** Get the first 5 positive integers that are divisible by 3.

**Solution (iota + filter + take):**

```cpp
#include <ranges>
#include <vector>
#include <iostream>

int main() {
    auto div3 = std::views::iota(1)
        | std::views::filter([](int x) { return x % 3 == 0; })
        | std::views::take(5);
    for (int x : div3) std::cout << x << ' ';  // 3 6 9 12 15
}
```

---

### 2.4 Count elements matching predicate (lambda)

**Problem:** Count how many elements in a vector are greater than 10.

**Solution:**

```cpp
#include <vector>
#include <algorithm>
#include <ranges>

std::vector<int> v = {5, 12, 3, 20, 8};
int count = std::ranges::count_if(v, [](int x) { return x > 10; });
// or: int count = std::count_if(v.begin(), v.end(), [](int x) { return x > 10; });
```

---

## 3. std::map (ordered)

### 3.1 Two Sum (value → index)

**Problem:** Same as 1.1; return two indices that add up to target.

**Solution (unordered_map is better; map works too):**

```cpp
#include <vector>
#include <unordered_map>

std::vector<int> twoSum(const std::vector<int>& nums, int target) {
    std::unordered_map<int, int> seen;  // value -> index
    for (int i = 0; i < (int)nums.size(); ++i) {
        int need = target - nums[i];
        if (auto it = seen.find(need); it != seen.end())
            return {it->second, i};
        seen[nums[i]] = i;
    }
    return {};
}
```

Use **std::map** if you need keys in sorted order for something else; for two sum, **unordered_map** is faster.

---

### 3.2 Group anagrams (sorted string as key)

**Problem:** Given a list of strings, group them so that anagrams are in the same group. Anagrams share the same sorted string.

**Example:** `["eat","tea","tan","ate","nat","bat"]` → `[["eat","tea","ate"], ["tan","nat"], ["bat"]]`

**Solution (map: sorted string → list of originals):**

```cpp
#include <vector>
#include <string>
#include <map>
#include <algorithm>

std::vector<std::vector<std::string>> groupAnagrams(std::vector<std::string>& strs) {
    std::map<std::string, std::vector<std::string>> groups;
    for (auto& s : strs) {
        std::string key = s;
        std::sort(key.begin(), key.end());
        groups[key].push_back(std::move(s));
    }
    std::vector<std::vector<std::string>> result;
    for (auto& [k, v] : groups)
        result.push_back(std::move(v));
    return result;
}
```

---

### 3.3 Frequency count (sorted iteration)

**Problem:** Count frequency of each character in a string; then list them in ascending character order.

**Solution (std::map):**

```cpp
#include <map>
#include <string>

std::map<char, int> charCount(const std::string& s) {
    std::map<char, int> count;
    for (char c : s) ++count[c];
    return count;
}
```

---

## 4. std::unordered_map (hash map)

### 4.1 Two Sum (classic)

Same as 3.1; **unordered_map** gives average O(1) lookup. Code shown in 3.1.

---

### 4.2 Subarray sum equals K

**Problem:** Count contiguous subarrays whose sum equals K.

**Example:** `nums = [1, 1, 1]`, `K = 2` → 2 (subarrays `[1,1]` and `[1,1]`).

**Approach:** Prefix sum + hash. For each prefix sum `sum`, count how many previous prefix sums were `sum - K`; add that to the result. Maintain **unordered_map&lt;prefix_sum, count&gt;** and iterate.

```cpp
#include <vector>
#include <unordered_map>

int subarraySum(const std::vector<int>& nums, int k) {
    std::unordered_map<int, int> prefix_count;
    prefix_count[0] = 1;
    int sum = 0, count = 0;
    for (int x : nums) {
        sum += x;
        count += prefix_count[sum - k];
        ++prefix_count[sum];
    }
    return count;
}
```

---

### 4.3 First non-repeating character

**Problem:** In a string, find the first character that appears exactly once; return its index or -1.

**Solution (two passes: count, then find first with count 1):**

```cpp
#include <string>
#include <unordered_map>

int firstUniqChar(const std::string& s) {
    std::unordered_map<char, int> count;
    for (char c : s) ++count[c];
    for (size_t i = 0; i < s.size(); ++i)
        if (count[s[i]] == 1) return static_cast<int>(i);
    return -1;
}
```

---

### 4.4 Top K frequent elements

**Problem:** Given an integer array, return the k most frequent elements. Order doesn’t matter.

**Example:** `[1,1,1,2,2,3]`, `k = 2` → `[1, 2]`

**Approach:** Count frequency with **unordered_map**; then either (a) sort (vector of pair&lt;count, value&gt;) and take top k, or (b) use **nth_element** / **partial_sort** on counts.

```cpp
#include <vector>
#include <unordered_map>
#include <algorithm>

std::vector<int> topKFrequent(std::vector<int>& nums, int k) {
    std::unordered_map<int, int> count;
    for (int x : nums) ++count[x];
    std::vector<std::pair<int, int>> pairs(count.begin(), count.end());
    std::nth_element(pairs.begin(), pairs.begin() + k, pairs.end(),
        [](const auto& a, const auto& b) { return a.second > b.second; });
    std::vector<int> result;
    for (int i = 0; i < k; ++i) result.push_back(pairs[i].first);
    return result;
}
```

---

## 5. Mixed: ranges + map/unordered_map

### 5.1 Words with frequency (ranges + unordered_map)

**Problem:** Given a vector of words, build a frequency map and then list words that appear more than once, in order of first occurrence (or alphabetically).

**Solution (frequency with unordered_map; filter with ranges):**

```cpp
#include <vector>
#include <string>
#include <unordered_map>
#include <ranges>

std::vector<std::string> wordsMoreThanOnce(const std::vector<std::string>& words) {
    std::unordered_map<std::string, int> count;
    for (const auto& w : words) ++count[w];
    std::vector<std::string> result;
    for (const auto& w : words)
        if (count[w] > 1) {
            result.push_back(w);
            count[w] = 0;  // avoid duplicates in result
        }
    return result;
}
```

---

### 5.2 Custom key for unordered_map (pair as key)

**Problem:** Count frequency of pairs (e.g. (x, y) coordinates). **std::unordered_map** needs a hash for the key; **std::map** only needs **operator&lt;**.

**Solution (use map for simplicity, or define hash for pair):**

```cpp
#include <map>
#include <vector>
#include <utility>

std::map<std::pair<int, int>, int> pairCount(const std::vector<std::pair<int, int>>& pairs) {
    std::map<std::pair<int, int>, int> count;
    for (const auto& p : pairs) ++count[p];
    return count;
}
```

For **unordered_map**, you’d provide **std::hash&lt;std::pair&lt;int,int&gt;&gt;** (or a custom key type with a hash).

---

## More problems

### Vectors (continued)

#### 1.6 Move zeroes to end

**Problem:** Move all zeros to the end in place; keep relative order of non-zero elements.

**Example:** `[0, 1, 0, 3, 12]` → `[1, 3, 12, 0, 0]`

**Solution (partition with lambda):**

```cpp
#include <vector>
#include <algorithm>

void moveZeroes(std::vector<int>& nums) {
    std::stable_partition(nums.begin(), nums.end(), [](int x) { return x != 0; });
}
```

Or two pointers: write index + scan, then fill rest with 0.

---

#### 1.7 Product of array except self

**Problem:** Return a vector where `out[i]` = product of all elements except `nums[i]`. No division; O(n).

**Example:** `[1, 2, 3, 4]` → `[24, 12, 8, 6]`

**Approach:** Prefix products from left, then from right (or one pass with a running product).

```cpp
#include <vector>

std::vector<int> productExceptSelf(const std::vector<int>& nums) {
    int n = static_cast<int>(nums.size());
    std::vector<int> out(n, 1);
    int left = 1, right = 1;
    for (int i = 0; i < n; ++i) {
        out[i] *= left;   left *= nums[i];
        out[n - 1 - i] *= right;   right *= nums[n - 1 - i];
    }
    return out;
}
```

---

#### 1.8 Find minimum in rotated sorted array

**Problem:** Sorted array was rotated; find the minimum. Assume distinct elements.

**Example:** `[3, 4, 5, 1, 2]` → 1

**Solution (binary search, or min_element for short):**

```cpp
#include <vector>
#include <algorithm>

int findMin(const std::vector<int>& nums) {
    return *std::ranges::min_element(nums);
}
```

For O(log n): binary search where you compare with `nums[0]` or `nums.back()` to know which half has the min.

---

#### 1.9 Maximum subarray sum (Kadane)

**Problem:** Find the contiguous subarray with the largest sum.

**Example:** `[-2, 1, -3, 4, -1, 2, 1, -5, 4]` → 6 (subarray `[4, -1, 2, 1]`)

**Solution:**

```cpp
#include <vector>
#include <algorithm>

int maxSubarraySum(const std::vector<int>& nums) {
    int best = nums[0], cur = nums[0];
    for (size_t i = 1; i < nums.size(); ++i) {
        cur = std::max(nums[i], cur + nums[i]);
        best = std::max(best, cur);
    }
    return best;
}
```

---

#### 1.10 Rotate array right by k

**Problem:** Rotate the vector to the right by k steps (last k elements wrap to the front).

**Example:** `[1, 2, 3, 4, 5]`, `k = 2` → `[4, 5, 1, 2, 3]`

**Solution (reverse three times):**

```cpp
#include <vector>
#include <algorithm>

void rotate(std::vector<int>& nums, int k) {
    int n = static_cast<int>(nums.size());
    if (n == 0) return;
    k %= n;
    std::reverse(nums.begin(), nums.end());
    std::reverse(nums.begin(), nums.begin() + k);
    std::reverse(nums.begin() + k, nums.end());
}
```

---

### Ranges and lambdas (continued)

#### 2.5 Partition: evens first, then odds

**Problem:** Reorder so all even numbers come before odd (order among evens/odds doesn’t matter).

**Solution:**

```cpp
#include <vector>
#include <algorithm>
#include <ranges>

void evensFirst(std::vector<int>& v) {
    std::ranges::partition(v, [](int x) { return x % 2 == 0; });
}
```

---

#### 2.6 Index of first element matching predicate

**Problem:** Return index of the first element &gt; 10, or -1 if none.

**Solution:**

```cpp
#include <vector>
#include <ranges>
#include <algorithm>

int firstIndexGreaterThan10(const std::vector<int>& v) {
    auto it = std::ranges::find_if(v, [](int x) { return x > 10; });
    if (it == v.end()) return -1;
    return static_cast<int>(it - v.begin());
}
```

---

#### 2.7 Chunk by size (first N elements per chunk)

**Problem:** Split a vector into chunks of size 3; last chunk may be smaller.

**Example:** `[1,2,3,4,5,6,7]` → `[[1,2,3], [4,5,6], [7]]`

**Solution (loop or ranges with views::chunk in C++23):**

```cpp
#include <vector>

std::vector<std::vector<int>> chunk(const std::vector<int>& v, size_t size) {
    std::vector<std::vector<int>> result;
    for (size_t i = 0; i < v.size(); i += size) {
        result.emplace_back(v.begin() + i,
            v.begin() + std::min(i + size, v.size()));
    }
    return result;
}
```

---

#### 2.8 Lazy: first 10 squares

**Problem:** Generate the first 10 perfect squares (1, 4, 9, …) without storing all in memory first.

**Solution (iota + transform + take):**

```cpp
#include <ranges>
#include <vector>
#include <iostream>

int main() {
    auto squares = std::views::iota(1)
        | std::views::transform([](int x) { return x * x; })
        | std::views::take(10);
    for (int x : squares) std::cout << x << ' ';  // 1 4 9 16 ...
}
```

---

### std::map / unordered_map (continued)

#### 3.4 Valid anagram

**Problem:** Two strings: are they anagrams (same characters, same counts)?

**Solution (unordered_map count, or sort both and compare):**

```cpp
#include <string>
#include <unordered_map>

bool isAnagram(std::string s, std::string t) {
    if (s.size() != t.size()) return false;
    std::unordered_map<char, int> count;
    for (char c : s) ++count[c];
    for (char c : t) if (--count[c] < 0) return false;
    return true;
}
```

---

#### 4.5 Intersection of two arrays (unique common elements)

**Problem:** Given two vectors, return a vector of unique elements that appear in both.

**Example:** `[1,2,2,1]`, `[2,2]` → `[2]`

**Solution (unordered_set for one, then check other):**

```cpp
#include <vector>
#include <unordered_set>

std::vector<int> intersection(std::vector<int>& a, std::vector<int>& b) {
    std::unordered_set<int> setA(a.begin(), a.end());
    std::unordered_set<int> seen;
    std::vector<int> out;
    for (int x : b) {
        if (setA.count(x) && seen.insert(x).second) out.push_back(x);
    }
    return out;
}
```

---

#### 4.6 Longest substring without repeating characters

**Problem:** Length of longest contiguous substring with all distinct characters.

**Example:** `"abcabcbb"` → 3 (`"abc"`)

**Approach:** Sliding window + **unordered_map&lt;char, index&gt;** (or last seen index). Extend right; if duplicate, move left past previous occurrence.

```cpp
#include <string>
#include <unordered_map>
#include <algorithm>

int lengthOfLongestSubstring(const std::string& s) {
    std::unordered_map<char, int> last;
    int start = 0, best = 0;
    for (int i = 0; i < (int)s.size(); ++i) {
        char c = s[i];
        if (last.count(c) && last[c] >= start)
            start = last[c] + 1;
        last[c] = i;
        best = std::max(best, i - start + 1);
    }
    return best;
}
```

---

#### 4.7 Contains duplicate (within distance k)

**Problem:** Are there two indices `i`, `j` with `nums[i] == nums[j]` and `|i - j| <= k`?

**Solution (unordered_map: value → last index):**

```cpp
#include <vector>
#include <unordered_map>

bool containsNearbyDuplicate(const std::vector<int>& nums, int k) {
    std::unordered_map<int, int> last;
    for (int i = 0; i < (int)nums.size(); ++i) {
        int x = nums[i];
        if (last.count(x) && i - last[x] <= k) return true;
        last[x] = i;
    }
    return false;
}
```

---

#### 4.8 Sort array by frequency (ascending), then by value (ascending)

**Problem:** Sort so that more frequent elements come first; if frequency is equal, smaller value first.

**Solution (count with unordered_map, then sort with lambda):**

```cpp
#include <vector>
#include <unordered_map>
#include <algorithm>

std::vector<int> sortByFrequency(const std::vector<int>& nums) {
    std::unordered_map<int, int> count;
    for (int x : nums) ++count[x];
    std::vector<int> out(nums.begin(), nums.end());
    std::ranges::sort(out, [&count](int a, int b) {
        int ca = count[a], cb = count[b];
        if (ca != cb) return ca > cb;
        return a < b;
    });
    return out;
}
```

---

### Mixed (continued)

#### 5.3 Find all numbers disappeared in an array

**Problem:** Vector of n integers; values in `[1, n]`. Some may appear twice, some missing. Return all numbers in `[1, n]` that do not appear.

**Example:** `[4,3,2,7,8,2,3,1]` (n=8) → `[5, 6]`

**Solution (mark seen in a set or in-place with sign):**

```cpp
#include <vector>
#include <unordered_set>
#include <ranges>

std::vector<int> findDisappeared(const std::vector<int>& nums) {
    std::unordered_set<int> seen(nums.begin(), nums.end());
    std::vector<int> out;
    for (int i = 1; i <= (int)nums.size(); ++i)
        if (!seen.count(i)) out.push_back(i);
    return out;
}
```

---

#### 5.4 Majority element (appears more than n/2 times)

**Problem:** Return the element that appears more than `n/2` times. Assume it exists.

**Solution (Boyer–Moore vote, or unordered_map count):**

```cpp
#include <vector>
#include <unordered_map>

int majorityElement(const std::vector<int>& nums) {
    std::unordered_map<int, int> count;
    for (int x : nums) ++count[x];
    int half = static_cast<int>(nums.size()) / 2;
    for (const auto& [val, c] : count)
        if (c > half) return val;
    return -1;
}
```

---

#### 5.5 Group strings by length

**Problem:** Group a list of strings by their length. Return map: length → vector of strings.

**Solution (map or unordered_map):**

```cpp
#include <vector>
#include <string>
#include <unordered_map>

std::unordered_map<size_t, std::vector<std::string>> groupByLength(
    const std::vector<std::string>& words) {
    std::unordered_map<size_t, std::vector<std::string>> groups;
    for (const auto& w : words) groups[w.size()].push_back(w);
    return groups;
}
```

---

## 6. 2D vectors (matrix / grid)

Problems that use **std::vector&lt;std::vector&lt;T&gt;&gt;** (matrix/grid). For 2D vector syntax and patterns see [Vector Reference](vector-reference.md#10-multi-dimensional-vectors).

### 6.1 Matrix transpose

**Problem:** Given a matrix (2D vector), return its transpose (rows become columns).

**Example:** `[[1,2,3],[4,5,6]]` (2×3) → `[[1,4],[2,5],[3,6]]` (3×2).

**Solution:**

```cpp
#include <vector>

std::vector<std::vector<int>> transpose(const std::vector<std::vector<int>>& mat) {
    if (mat.empty()) return {};
    int R = static_cast<int>(mat.size()), C = static_cast<int>(mat[0].size());
    std::vector<std::vector<int>> out(C, std::vector<int>(R));
    for (int i = 0; i < R; ++i)
        for (int j = 0; j < C; ++j)
            out[j][i] = mat[i][j];
    return out;
}
```

---

### 6.2 Rotate image 90 degrees clockwise

**Problem:** N×N matrix; rotate in place 90 degrees clockwise.

**Approach:** Transpose then reverse each row; or rotate in layers (four-way swap per cell).

**Solution (transpose + reverse each row):**

```cpp
#include <vector>
#include <algorithm>

void rotate(std::vector<std::vector<int>>& mat) {
    int n = static_cast<int>(mat.size());
    for (int i = 0; i < n; ++i)
        for (int j = i + 1; j < n; ++j)
            std::swap(mat[i][j], mat[j][i]);
    for (auto& row : mat)
        std::reverse(row.begin(), row.end());
}
```

---

### 6.3 Search in a 2D sorted matrix (rows and columns sorted)

**Problem:** Each row is sorted left to right; each column is sorted top to bottom. Find if **target** exists.

**Approach:** Start from top-right (or bottom-left). If current &gt; target, move left; if current &lt; target, move down. O(rows + cols).

**Solution:**

```cpp
#include <vector>

bool searchMatrix(const std::vector<std::vector<int>>& mat, int target) {
    if (mat.empty() || mat[0].empty()) return false;
    int r = 0, c = static_cast<int>(mat[0].size()) - 1;
    while (r < (int)mat.size() && c >= 0) {
        if (mat[r][c] == target) return true;
        if (mat[r][c] > target) --c;
        else ++r;
    }
    return false;
}
```

---

### 6.4 Row with maximum sum

**Problem:** Return the index of the row that has the largest sum (or the row itself).

**Solution:**

```cpp
#include <vector>
#include <numeric>
#include <algorithm>

int rowWithMaxSum(const std::vector<std::vector<int>>& mat) {
    int best = INT_MIN, bestRow = -1;
    for (size_t i = 0; i < mat.size(); ++i) {
        int sum = std::accumulate(mat[i].begin(), mat[i].end(), 0);
        if (sum > best) { best = sum; bestRow = static_cast<int>(i); }
    }
    return bestRow;
}
```

---

### 6.5 Diagonal sum (main diagonal)

**Problem:** Square matrix; return sum of main diagonal (i == j).

**Solution:**

```cpp
#include <vector>

int diagonalSum(const std::vector<std::vector<int>>& mat) {
    int n = static_cast<int>(mat.size()), sum = 0;
    for (int i = 0; i < n; ++i) sum += mat[i][i];
    return sum;
}
```

For both diagonals (main + anti): add **mat[i][n - 1 - i]**; if **n** is odd, subtract the center once (it was counted twice).

---

### 6.6 Reshape matrix

**Problem:** Given 2D matrix and (r, c), reshape so the new matrix has r rows and c columns (row-major order). If impossible (size mismatch), return original.

**Example:** `mat = [[1,2],[3,4]]`, r=1, c=4 → `[[1,2,3,4]]`.

**Solution (flatten then fill):**

```cpp
#include <vector>

std::vector<std::vector<int>> matrixReshape(const std::vector<std::vector<int>>& mat, int r, int c) {
    int R = static_cast<int>(mat.size()), C = static_cast<int>(mat[0].size());
    if (R * C != r * c) return mat;
    std::vector<std::vector<int>> out(r, std::vector<int>(c));
    int idx = 0;
    for (int i = 0; i < R; ++i)
        for (int j = 0; j < C; ++j) {
            int row = idx / c, col = idx % c;
            out[row][col] = mat[i][j];
            ++idx;
        }
    return out;
}
```

---

### 6.7 Set matrix zeroes (in place)

**Problem:** If an element is 0, set its entire row and column to 0. Do it in place.

**Approach:** First pass: mark which rows and columns must be zero (e.g. use first row and first column as flags, or two **vector&lt;bool&gt;** of size R and C). Second pass: set zeros.

**Solution (use first row/col as flags):**

```cpp
#include <vector>

void setZeroes(std::vector<std::vector<int>>& mat) {
    int R = static_cast<int>(mat.size()), C = static_cast<int>(mat[0].size());
    bool firstRow = false, firstCol = false;
    for (int j = 0; j < C; ++j) if (mat[0][j] == 0) firstRow = true;
    for (int i = 0; i < R; ++i) if (mat[i][0] == 0) firstCol = true;
    for (int i = 1; i < R; ++i)
        for (int j = 1; j < C; ++j)
            if (mat[i][j] == 0) mat[i][0] = mat[0][j] = 0;
    for (int i = 1; i < R; ++i)
        for (int j = 1; j < C; ++j)
            if (mat[i][0] == 0 || mat[0][j] == 0) mat[i][j] = 0;
    if (firstRow) for (int j = 0; j < C; ++j) mat[0][j] = 0;
    if (firstCol) for (int i = 0; i < R; ++i) mat[i][0] = 0;
}
```

---

## 7. Quick reference: when to use what

| Need | Prefer |
|------|--------|
| Contiguous sequence, index by position | **std::vector** |
| Sorted iteration, O(log n) lookup/insert | **std::map** |
| O(1) average lookup/insert, no order | **std::unordered_map** |
| Filter/transform pipeline, lazy | **std::views::filter**, **transform**, **take** |
| Custom sort/comparison | **std::ranges::sort** + lambda |
| Count/find with predicate | **std::ranges::count_if**, **find_if** + lambda |

---

## See also

- [Containers](containers.md) – which container to use
- [STL Containers](stl-containers.md) – vector, map, unordered_map API
- [Ranges & Views](ranges-and-views.md) – range algorithms and views
- [Lambdas](lambdas.md) – capture and use in algorithms
- [Lazy evaluation](lazy-evaluation.md) – views and pipelines
