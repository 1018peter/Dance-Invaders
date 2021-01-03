from math import floor

n = 32
p = 1
layer = 0
while p < n:
    k = p
    while k >= 1:
        j = k % p
        state = {}
        for m in range (0, n):
            state[m] = False
        while j < n - k:
            for i in range(0, k):
                if floor((i + j) / (2*p)) == floor((i + j + k) / (2 * p)):
                    state[i+j] = True
                    state[i+j+k] = True
                    print(f"""alien_comparator(unordered, sort_layer[{layer}][{i+j}],sort_layer[{layer}][{i+j+k}], sort_layer[{layer+1}][{i+j}], sort_layer[{layer+1}][{i+j+k}]);""")
            j += 2 * k
        for m in range (0, n):
            if state[m] == False:
                print(f"assign sort_layer[{layer+1}][{m}] = sort_layer[{layer}][{m}];")
        k  = floor(k / 2)
        layer+=1
    p *= 2
