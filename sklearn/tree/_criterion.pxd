# Authors: Gilles Louppe <g.louppe@gmail.com>
#          Peter Prettenhofer <peter.prettenhofer@gmail.com>
#          Brian Holt <bdholt1@gmail.com>
#          Joel Nothman <joel.nothman@gmail.com>
#          Arnaud Joly <arnaud.v.joly@gmail.com>
#          Jacob Schreiber <jmschreiber91@gmail.com>
#
# License: BSD 3 clause

# See _criterion.pyx for implementation details.

from ._tree cimport DTYPE_t          # Type of X
from ._tree cimport DOUBLE_t         # Type of y, sample_weight
from ._tree cimport SIZE_t           # Type for indices and counters
from ._tree cimport INT32_t          # Signed 32 bit integer
from ._tree cimport UINT32_t         # Unsigned 32 bit integer

cdef packed struct hist_struct:
    SIZE_t* left
    SIZE_t* right

cdef class Criterion:
    # The criterion computes the impurity of a node and the reduction of
    # impurity of a split on that node. It also computes the output statistics
    # such as the mean in regression and class probabilities in classification.

    # Internal structures
    cdef const DOUBLE_t[:, ::1] y        # Values of y
    cdef DOUBLE_t* sample_weight         # Sample weights

    cdef SIZE_t* samples                 # Sample indices in X, y
    cdef SIZE_t start                    # samples[start:pos] are the samples in the left node
    cdef SIZE_t pos                      # samples[pos:end] are the samples in the right node
    cdef SIZE_t end

    cdef SIZE_t n_outputs                # Number of outputs
    cdef SIZE_t n_samples                # Number of samples
    cdef SIZE_t n_node_samples           # Number of samples in the node (end-start)
    cdef double weighted_n_samples       # Weighted number of samples (in total)
    cdef double weighted_n_node_samples  # Weighted number of samples in the node
    cdef double weighted_n_left          # Weighted number of samples in the left node
    cdef double weighted_n_right         # Weighted number of samples in the right node

    cdef SIZE_t n_bins
    cdef SIZE_t n_features
    cdef SIZE_t n_single_classes                # number of classes for the first target of y
    cdef hist_struct[::1] histograms
    cdef SIZE_t[:,::1] current_hist

    # The criterion object is maintained such that left and right collected
    # statistics correspond to samples[start:pos] and samples[pos:end].

    # Methods
    cdef int init(self, const DOUBLE_t[:, ::1] y, DOUBLE_t* sample_weight,
                  double weighted_n_samples, SIZE_t* samples, SIZE_t start,
                  SIZE_t end) nogil except -1
    cdef int reset(self) nogil except -1
    cdef int reverse_reset(self) nogil except -1
    cdef int update(self, SIZE_t new_pos) nogil except -1
    cdef double node_impurity(self) nogil
    cdef void children_impurity(self, double* impurity_left,
                                double* impurity_right) nogil
    cdef void node_value(self, double* dest) nogil
    cdef double impurity_improvement(self, double impurity_parent,
                                     double impurity_left,
                                     double impurity_right) nogil
    cdef double proxy_impurity_improvement(self) nogil

    # function placeholders for HistGini -> any other criteria doesn't use these
    cdef int init_histograms(self, SIZE_t num_bins, SIZE_t n_features, SIZE_t n_classes) except -1
    cdef int hist_node_init(self) nogil except -1
    cdef int insert_histograms(self, SIZE_t feature_idx, SIZE_t batch_size,
                                    SIZE_t[::1] bin_idcs, SIZE_t[::1] batch_y) nogil
    cdef void get_impurity_reductions(
            self,
            double * impurity_curr, double * impurity_left,double * impurity_right,
            double * variance_curr, double * variance_left, double * variance_right,
            SIZE_t f, SIZE_t bin
    ) nogil

cdef class ClassificationCriterion(Criterion):
    """Abstract criterion for classification."""

    cdef SIZE_t[::1] n_classes
    cdef SIZE_t max_n_classes

    cdef double[:, ::1] sum_total   # The sum of the weighted count of each label.
    cdef double[:, ::1] sum_left    # Same as above, but for the left side of the split
    cdef double[:, ::1] sum_right   # Same as above, but for the right side of the split

cdef class RegressionCriterion(Criterion):
    """Abstract regression criterion."""

    cdef double sq_sum_total

    cdef double[::1] sum_total   # The sum of w*y.
    cdef double[::1] sum_left    # Same as above, but for the left side of the split
    cdef double[::1] sum_right   # Same as above, but for the right side of the split
